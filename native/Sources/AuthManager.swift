import SwiftUI
import AuthenticationServices

/// Sign in with Apple gate, replacing the web app's Supabase email auth.
/// The Apple user id is the stable identity; persisted across launches.
@MainActor
final class AuthManager: NSObject, ObservableObject {
    @Published var userID: String?
    @Published var displayName: String?

    private let idKey = "appleUserID"
    private let nameKey = "appleUserName"

    var isSignedIn: Bool { userID != nil }

    override init() {
        super.init()
        userID = UserDefaults.standard.string(forKey: idKey)
        displayName = UserDefaults.standard.string(forKey: nameKey)
        if let uid = userID { revalidate(uid) }
    }

    /// Confirm the stored credential is still authorized; sign out if revoked.
    private func revalidate(_ uid: String) {
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: uid) { [weak self] state, _ in
            guard state != .authorized else { return }
            Task { @MainActor in self?.signOut() }
        }
    }

    func handle(_ result: Result<ASAuthorization, Error>) {
        guard case .success(let auth) = result,
              let cred = auth.credential as? ASAuthorizationAppleIDCredential else { return }
        userID = cred.user
        UserDefaults.standard.set(cred.user, forKey: idKey)
        if let given = cred.fullName?.givenName, !given.isEmpty {
            displayName = given
            UserDefaults.standard.set(given, forKey: nameKey)
        }
    }

    func signOut() {
        userID = nil
        displayName = nil
        UserDefaults.standard.removeObject(forKey: idKey)
        UserDefaults.standard.removeObject(forKey: nameKey)
    }
}
