import SwiftUI

struct AboutView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "palm")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(PalmTheme.sidebarTint)
                .frame(width: 82, height: 82)
                .glassSurface(tint: PalmTheme.sidebarTint.opacity(0.14))

            VStack(spacing: 8) {
                Text("Palm Sync")
                    .font(.largeTitle.weight(.semibold))

                Text(label(ptBR: "criado por Luiz Ferrarezi", en: "created by Luiz Ferrarezi"))
                    .font(.headline)

                Link("https://github.com/lferrarezi", destination: URL(string: "https://github.com/lferrarezi")!)
                    .font(.callout)

                Text("\(label(ptBR: "versão", en: "version")) \(AppVersionInfo.version)")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(spacing: 6) {
                Text(label(ptBR: "Aplicação em português brasileiro e inglês.", en: "Application in Brazilian Portuguese and English."))
                    .font(.callout)
                Text("GitHub: lferrarezi/Palm-Sync")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(label(ptBR: "Fechar", en: "Close")) {
                dismiss()
            }
            .glassButtonStyle(prominent: true)
            .padding(.top, 4)
        }
        .padding(30)
        .frame(width: 440)
        .background(AppBackground())
    }

    private func label(ptBR: String, en: String) -> String {
        LocalizedLabel(ptBR: ptBR, en: en).text(store.language)
    }
}

