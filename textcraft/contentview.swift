import SwiftUI
import StoreKit
import PhotosUI

struct ContentView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var cardStore: CardStore
    @State private var inputText = ""
    @State private var selectedTemplate: CardTemplate = .gradientSunset
    @State private var fontSize: CGFloat = 24
    @State private var showingPaywall = false
    @State private var showingShareSheet = false
    @State private var generatedImage: UIImage?
    @State private var isPremiumTemplate = false
    @State private var showPremiumAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerView
                    
                    // Text Input
                    textInputView
                    
                    // Font Size Slider
                    fontSizeView
                    
                    // Template Picker
                    templatePickerView
                    
                    // Card Preview
                    cardPreviewView
                    
                    // Action Buttons
                    actionButtonsView
                }
                .padding()
            }
            .navigationTitle("TextCraft")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if subscriptionManager.isSubscribed {
                        Label("Pro", systemImage: "crown.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .alert("解锁高级版", isPresented: $showPremiumAlert) {
            Button("查看订阅方案") { showingPaywall = true }
            Button("取消", role: .cancel) {}
        } message: {
            Text("这个模板需要订阅高级版才能使用")
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = generatedImage {
                ShareSheet(image: image)
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("文字变卡片")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("输入文字，选择模板，生成精美卡片")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Text Input
    private var textInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("输入文字")
                .font(.headline)
            TextEditor(text: $inputText)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Font Size
    private var fontSizeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("字号: \(Int(fontSize))")
                .font(.headline)
            HStack {
                Image(systemName: "textformat.size.smaller")
                Slider(value: $fontSize, in: 14...48, step: 2)
                Image(systemName: "textformat.size.larger")
            }
        }
    }
    
    // MARK: - Template Picker
    private var templatePickerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择模板")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CardTemplate.allCases) { template in
                        templateThumbView(template)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func templateThumbView(_ template: CardTemplate) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 12)
                .fill(template.backgroundGradient)
                .frame(width: 70, height: 90)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedTemplate == template ? Color.accentColor : Color.clear, lineWidth: 3)
                )
                .overlay(alignment: .topTrailing) {
                    if template.isPremium && !subscriptionManager.isSubscribed {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(Color.orange))
                            .padding(4)
                    }
                }
                .onTapGesture {
                    if template.isPremium && !subscriptionManager.isSubscribed {
                        isPremiumTemplate = true
                        showPremiumAlert = true
                    } else {
                        selectedTemplate = template
                    }
                }
            
            Text(template.displayName)
                .font(.caption2)
                .lineLimit(1)
        }
    }
    
    // MARK: - Card Preview
    private var cardPreviewView: some View {
        VStack(spacing: 12) {
            Text("预览")
                .font(.headline)
            
            CardView(
                text: inputText.isEmpty ? "在这里输入文字..." : inputText,
                template: selectedTemplate,
                fontSize: fontSize,
                showWatermark: !subscriptionManager.isSubscribed
            )
            .frame(width: 300, height: 400)
            .id(inputText) // refresh on text change
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            Button(action: generateAndShare) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("生成并分享")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            if !subscriptionManager.isSubscribed {
                Button(action: { showingPaywall = true }) {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("解锁高级版 - 去水印 & 全部模板")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Generate & Share
    private func generateAndShare() {
        let renderer = ImageRenderer(content:
            CardView(
                text: inputText,
                template: selectedTemplate,
                fontSize: fontSize,
                showWatermark: !subscriptionManager.isSubscribed
            )
            .frame(width: 1080, height: 1440)
        )
        renderer.scale = 3.0
        if let image = renderer.uiImage {
            generatedImage = image
            showingShareSheet = true
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
