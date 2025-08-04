import SwiftUI
import PhotosUI

struct ProfileHeaderView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var showingImagePicker: Bool
    @Binding var isEditingNick: Bool
    @Binding var newNick: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ProfileAvatarView(
                profileViewModel: profileViewModel,
                showingImagePicker: $showingImagePicker
            )
            
            ProfileInfoView(
                profileViewModel: profileViewModel,
                isEditingNick: $isEditingNick,
                newNick: $newNick
            )
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

private struct ProfileAvatarView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var showingImagePicker: Bool
    
    var body: some View {
        Button(action: { showingImagePicker = true }) {
            if let profileImage = profileViewModel.currentUser?.profileImage,
               let url = URL(string: profileImage) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                )
            } else {
                DefaultAvatarView(isUploading: profileViewModel.isUploadingProfileImage)
            }
        }
        .disabled(profileViewModel.isUploadingProfileImage)
    }
}

private struct DefaultAvatarView: View {
    let isUploading: Bool
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 60, height: 60)
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                    
                    if isUploading {
                        ProgressView()
                            .scaleEffect(0.5)
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
            )
    }
}

private struct ProfileInfoView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var isEditingNick: Bool
    @Binding var newNick: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            UsernameEditView(
                profileViewModel: profileViewModel,
                isEditingNick: $isEditingNick,
                newNick: $newNick
            )
            
            if let email = profileViewModel.currentUser?.email {
                Text(email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            SocialLinksView(user: profileViewModel.currentUser)
        }
    }
}

private struct UsernameEditView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var isEditingNick: Bool
    @Binding var newNick: String
    
    var body: some View {
        if isEditingNick {
            HStack(spacing: 4) {
                Text("@")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                TextField("username", text: $newNick)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onSubmit {
                        saveUsername()
                    }
                
                Button(action: saveUsername) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        } else {
            Text(profileViewModel.currentUser?.username ?? "@user")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .onTapGesture {
                    newNick = (profileViewModel.currentUser?.username ?? "@user").replacingOccurrences(of: "@", with: "")
                    isEditingNick = true
                }
        }
    }
    
    private func saveUsername() {
        let nick = newNick.trimmingCharacters(in: .whitespacesAndNewlines)
        if !nick.isEmpty {
            let username = nick.hasPrefix("@") ? nick : "@" + nick
            profileViewModel.updateUsername(username)
        }
        isEditingNick = false
    }
}

private struct SocialLinksView: View {
    let user: User?
    
    var body: some View {
        if let user = user, !user.socialLinks.isEmpty {
            HStack(spacing: 14) {
                ForEach(user.socialLinks) { link in
                    Button(action: {
                        if let url = URL(string: link.url) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: link.platform.icon)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(width: 28, height: 28)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
} 