import SwiftData
import SwiftUI

struct MuseumInfoView: View {
    @Environment(ContentSyncService.self) private var sync
    @Environment(\.dismiss) private var dismiss
    @Query private var museums: [MuseumEntity]
    @Query(
        filter: #Predicate<LanguageEntity> { $0.isActive },
        sort: [SortDescriptor(\LanguageEntity.sort), SortDescriptor(\LanguageEntity.code)]
    )
    private var languages: [LanguageEntity]

    @Query(sort: [SortDescriptor(\PageEntity.sort), SortDescriptor(\PageEntity.slug)])
    private var pages: [PageEntity]

    private var languageContext: LanguageContext {
        EntityToUI.languageContext(
            museum: museums.first,
            languages: languages,
            selectedCode: sync.selectedLanguageCode
        )
    }

    private var pageItems: [PageUI] {
        pages.map { EntityToUI.page($0, in: languageContext) }
    }

    private var contact: MuseumContactUI? {
        guard let museum = museums.first else { return nil }
        let contact = EntityToUI.museumContact(museum)
        return contact.isEmpty ? nil : contact
    }

    var body: some View {
        NavigationStack {
            List {
                if pageItems.isEmpty, contact == nil {
                    Section {
                        ContentStateView(
                            state: .empty(
                                "No information",
                                "The museum has not published any practical information yet."
                            )
                        ) {}
                    }
                }

                if !pageItems.isEmpty {
                    PageListSectionView(pages: pageItems)
                }

                if let contact {
                    MuseumContactSectionView(contact: contact)
                }
            }
            .navigationTitle("Information")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: PageUI.self) { page in
                PageDetailView(page: pageDetail(for: page.id))
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }

    private func pageDetail(for id: String) -> PageDetailUI {
        guard let entity = pages.first(where: { $0.id == id }) else {
            return PageDetailUI(id: id, title: "", body: "")
        }
        return EntityToUI.pageDetail(entity, in: languageContext)
    }
}
