-- ActiveTomato Database Schema for Supabase

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User profiles table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    display_name TEXT,
    total_points INTEGER DEFAULT 0,
    current_level INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User settings/preferences
CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE,
    sound_enabled BOOLEAN DEFAULT true,
    interval_sound_enabled BOOLEAN DEFAULT true,
    tick_sound_enabled BOOLEAN DEFAULT false,
    reminder_enabled BOOLEAN DEFAULT false,
    reminder_interval INTEGER DEFAULT 30,
    auto_start_enabled BOOLEAN DEFAULT false,
    auto_series_enabled BOOLEAN DEFAULT false,
    default_series_target INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Pomodoro sessions (individual completed pomodoros)
CREATE TABLE IF NOT EXISTS public.pomodoro_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    session_type TEXT NOT NULL CHECK (session_type IN ('work', 'short_break', 'long_break')),
    duration_seconds INTEGER NOT NULL,
    points_earned INTEGER DEFAULT 0,
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    date DATE DEFAULT CURRENT_DATE
);

-- Daily activity summary (for the GitHub-style grid)
CREATE TABLE IF NOT EXISTS public.daily_activity (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    pomodoros_completed INTEGER DEFAULT 0,
    total_focus_minutes INTEGER DEFAULT 0,
    points_earned INTEGER DEFAULT 0,
    UNIQUE(user_id, date)
);

-- Activity log entries
CREATE TABLE IF NOT EXISTS public.activity_log (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Timer state for real-time sync across devices
CREATE TABLE IF NOT EXISTS public.timer_state (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    is_running BOOLEAN DEFAULT false,
    mode TEXT DEFAULT 'work' CHECK (mode IN ('work', 'shortBreak', 'longBreak')),
    time_left INTEGER DEFAULT 1500,
    started_at TIMESTAMPTZ,
    series_target INTEGER DEFAULT 1,
    series_progress INTEGER DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_user_date ON public.pomodoro_sessions(user_id, date);
CREATE INDEX IF NOT EXISTS idx_daily_activity_user_date ON public.daily_activity(user_id, date);
CREATE INDEX IF NOT EXISTS idx_activity_log_user_created ON public.activity_log(user_id, created_at DESC);

-- Row Level Security (RLS) Policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pomodoro_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timer_state ENABLE ROW LEVEL SECURITY;

-- Profiles: users can only see/edit their own profile
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Settings: users can only see/edit their own settings
CREATE POLICY "Users can view own settings" ON public.user_settings
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own settings" ON public.user_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own settings" ON public.user_settings
    FOR UPDATE USING (auth.uid() = user_id);

-- Pomodoro sessions: users can only see/create their own
CREATE POLICY "Users can view own sessions" ON public.pomodoro_sessions
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own sessions" ON public.pomodoro_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Daily activity: users can only see/manage their own
CREATE POLICY "Users can view own daily activity" ON public.daily_activity
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own daily activity" ON public.daily_activity
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own daily activity" ON public.daily_activity
    FOR UPDATE USING (auth.uid() = user_id);

-- Activity log: users can only see/create their own
CREATE POLICY "Users can view own activity log" ON public.activity_log
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own activity log" ON public.activity_log
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Timer state: users can only see/manage their own
CREATE POLICY "Users can view own timer state" ON public.timer_state
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own timer state" ON public.timer_state
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own timer state" ON public.timer_state
    FOR UPDATE USING (auth.uid() = user_id);

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email)
    VALUES (NEW.id, NEW.email);

    INSERT INTO public.user_settings (user_id)
    VALUES (NEW.id);

    INSERT INTO public.timer_state (user_id)
    VALUES (NEW.id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update daily activity
CREATE OR REPLACE FUNCTION public.update_daily_activity(
    p_user_id UUID,
    p_date DATE,
    p_pomodoros INTEGER,
    p_minutes INTEGER,
    p_points INTEGER
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO public.daily_activity (user_id, date, pomodoros_completed, total_focus_minutes, points_earned)
    VALUES (p_user_id, p_date, p_pomodoros, p_minutes, p_points)
    ON CONFLICT (user_id, date)
    DO UPDATE SET
        pomodoros_completed = daily_activity.pomodoros_completed + p_pomodoros,
        total_focus_minutes = daily_activity.total_focus_minutes + p_minutes,
        points_earned = daily_activity.points_earned + p_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user points
CREATE OR REPLACE FUNCTION public.add_user_points(
    p_user_id UUID,
    p_points INTEGER
)
RETURNS INTEGER AS $$
DECLARE
    new_total INTEGER;
BEGIN
    UPDATE public.profiles
    SET total_points = total_points + p_points,
        updated_at = NOW()
    WHERE id = p_user_id
    RETURNING total_points INTO new_total;

    RETURN new_total;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable Realtime for timer_state (for cross-device sync)
-- Note: Also enable in Supabase Dashboard > Database > Replication > timer_state
ALTER PUBLICATION supabase_realtime ADD TABLE public.timer_state;
