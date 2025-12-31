//
//  CachedAsyncImage.swift
//  GrokMode
//
//  Created by Abdulaziz Albahar on 12/31/25.
//

import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View, ErrorPlaceholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    let errorPlaceholder: (Error) -> ErrorPlaceholder

    @State private var loadedImage: LoadedImageState = .loading

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder errorPlaceholder: @escaping (Error) -> ErrorPlaceholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
        self.errorPlaceholder = errorPlaceholder
    }

    var body: some View {
        Group {
            switch loadedImage {
            case .loading:
                placeholder()
            case .success(let image):
                content(Image(uiImage: image))
            case .failure(let error):
                errorPlaceholder(error)
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url = url else {
            return
        }

        loadedImage = .loading

        do {
            let image = try await ImageCache.shared.image(for: url)
            loadedImage = .success(image)
        } catch {
            loadedImage = .failure(error)
        }
    }
}

private enum LoadedImageState: Equatable {
    case loading
    case success(UIImage)
    case failure(Error)

    static func == (lhs: LoadedImageState, rhs: LoadedImageState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.success(let img1), .success(let img2)):
            return img1 === img2
        case (.failure, .failure):
            return true
        default:
            return false
        }
    }
}

extension CachedAsyncImage where ErrorPlaceholder == Placeholder {
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.init(
            url: url,
            content: content,
            placeholder: placeholder,
            errorPlaceholder: { _ in placeholder() }
        )
    }
}

extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView>, ErrorPlaceholder == ProgressView<EmptyView, EmptyView> {
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(
            url: url,
            content: content,
            placeholder: { ProgressView() },
            errorPlaceholder: { _ in ProgressView() }
        )
    }
}

extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView>, ErrorPlaceholder == ProgressView<EmptyView, EmptyView> {
    init(url: URL?) {
        self.init(
            url: url,
            content: { $0 },
            placeholder: { ProgressView() },
            errorPlaceholder: { _ in ProgressView() }
        )
    }
}
