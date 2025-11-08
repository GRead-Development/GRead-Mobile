import SwiftUI

struct GuestProfileView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gray.opacity(0.5))

                    Text("Guest User")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("You are browsing the app as a guest")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)

                VStack(spacing: 12) {
                    VStack(spacing: 8) {
                        Label("View Activity", systemImage: "flame.fill")
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Browse activity feed and see what others are sharing")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                    VStack(spacing: 8) {
                        Label("Join Groups", systemImage: "person.3.fill")
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Explore groups and their activities")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                    VStack(spacing: 8) {
                        Label("Limited Access", systemImage: "lock.fill")
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Sign in to post, comment, and send messages")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 16)

                Spacer()

                VStack(spacing: 12) {
                    NavigationLink(destination: LoginRegisterView()) {
                        HStack {
                            Image(systemName: "person.fill")
                            Text("Sign In or Create Account")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    Button(action: logout) {
                        HStack {
                            Image(systemName: "arrow.backward.circle.fill")
                            Text("Back to Start")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.black)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Profile")
            .background(Color.white)
        }
    }

    private func logout() {
        authManager.logout()
    }
}

#Preview {
    GuestProfileView()
        .environmentObject(AuthManager.shared)
}
