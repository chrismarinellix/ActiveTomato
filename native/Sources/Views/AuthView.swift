import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @ObservedObject var auth: AuthManager

    var body: some View {
        ScrollView {
            EInkCard {
                VStack(spacing: 30) {
                    VStack(spacing: 10) {
                        Text("ACTIVETOMATO")
                            .font(Theme.display(26, .semibold))
                            .tracking(5)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundStyle(Theme.ink)
                        Text("High-Definition Pomodoro Timer")
                            .font(Theme.mono(11))
                            .foregroundStyle(Theme.gray888)
                    }
                    .padding(.top, 20)

                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName]
                    } onCompletion: { result in
                        auth.handle(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .frame(maxWidth: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                    Text("Your sessions sync privately across your\nApple devices via iCloud.")
                        .font(Theme.mono(10))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.gray999)
                        .padding(.bottom, 20)
                }
            }
            .padding()
            .padding(.top, 60)
        }
    }
}
