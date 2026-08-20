import SwiftUI

struct MuseumContactSectionView: View {
    let contact: MuseumContactUI

    var body: some View {
        Section("Practical information") {
            if !contact.address.isEmpty {
                if let mapsURL = contact.mapsURL {
                    Link(destination: mapsURL) {
                        Label(contact.address, systemImage: "mappin.and.ellipse")
                    }
                } else {
                    Label(contact.address, systemImage: "mappin.and.ellipse")
                }
            }

            if !contact.phone.isEmpty, let url = URL(string: "tel:\(contact.phone)") {
                Link(destination: url) {
                    Label(contact.phone, systemImage: "phone")
                }
            }

            if !contact.email.isEmpty, let url = URL(string: "mailto:\(contact.email)") {
                Link(destination: url) {
                    Label(contact.email, systemImage: "envelope")
                }
            }

            if let websiteURL = contact.websiteURL {
                Link(destination: websiteURL) {
                    Label("Website", systemImage: "safari")
                }
            }
        }
    }
}
