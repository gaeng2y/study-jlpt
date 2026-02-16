import Flutter
import SwiftUI
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NativeStudyEmbeddedView")
    else {
      return
    }

    let eventChannel = FlutterMethodChannel(
      name: "studyjlpt/native_study",
      binaryMessenger: registrar.messenger()
    )

    let factory = NativeStudyPlatformViewFactory(
      messenger: registrar.messenger(),
      eventChannel: eventChannel
    )
    registrar.register(factory, withId: "studyjlpt/native_study_view")
  }
}

final class NativeStudyPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  private let eventChannel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger, eventChannel: FlutterMethodChannel) {
    self.messenger = messenger
    self.eventChannel = eventChannel
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    let values = args as? [String: Any] ?? [:]
    return NativeStudyPlatformView(
      frame: frame,
      viewId: viewId,
      values: values,
      eventChannel: eventChannel
    )
  }
}

final class NativeStudyPlatformView: NSObject, FlutterPlatformView {
  private let container = UIView()

  init(
    frame: CGRect,
    viewId: Int64,
    values: [String: Any],
    eventChannel: FlutterMethodChannel
  ) {
    super.init()

    let contentId = (values["contentId"] as? String) ?? ""
    let jp = (values["jp"] as? String) ?? ""
    let reading = (values["reading"] as? String) ?? ""
    let meaningKo = (values["meaningKo"] as? String) ?? ""
    let kind = (values["kind"] as? String) ?? "vocab"
    let jlptLevel = (values["jlptLevel"] as? String) ?? "N5"

    let root = NativeEmbeddedStudyCardView(
      jp: jp,
      reading: reading,
      meaningKo: meaningKo,
      kind: kind,
      jlptLevel: jlptLevel,
      onAgain: {
        eventChannel.invokeMethod(
          "onGrade",
          arguments: ["grade": "again", "contentId": contentId]
        )
      },
      onGood: {
        eventChannel.invokeMethod(
          "onGrade",
          arguments: ["grade": "good", "contentId": contentId]
        )
      }
    )

    let host = UIHostingController(rootView: root)
    host.view.backgroundColor = .clear
    host.view.translatesAutoresizingMaskIntoConstraints = false

    container.backgroundColor = .clear
    container.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      host.view.topAnchor.constraint(equalTo: container.topAnchor),
      host.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
  }

  func view() -> UIView {
    container
  }
}

private struct NativeEmbeddedStudyCardView: View {
  let jp: String
  let reading: String
  let meaningKo: String
  let kind: String
  let jlptLevel: String
  let onAgain: () -> Void
  let onGood: () -> Void
  @State private var dragX: CGFloat = 0
  @State private var deciding = false
  private let swipeThreshold: CGFloat = 90

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color(red: 0.93, green: 0.96, blue: 1.0), Color.white],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack(spacing: 14) {
        HStack {
          Text("\(kind) · \(jlptLevel)")
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.thinMaterial)
            .clipShape(Capsule())
          Spacer()
        }

        Spacer()

        Text(jp)
          .font(.system(size: 46, weight: .bold))
        Text(reading)
          .font(.title2)
          .foregroundStyle(.secondary)
        Text(meaningKo)
          .font(.title3)

        Spacer()

        HStack(spacing: 14) {
          Button(action: onAgain) {
            Label("Again", systemImage: "arrow.counterclockwise")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.bordered)

          Button(action: onGood) {
            Label("Good", systemImage: "hand.thumbsup.fill")
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
        }
        Text("왼쪽 스와이프 Again · 오른쪽 스와이프 Good")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      .padding(20)
      .offset(x: dragX)
      .rotationEffect(.degrees(Double(dragX / 18)))
      .overlay(alignment: .topLeading) {
        Text("AGAIN")
          .font(.headline)
          .fontWeight(.black)
          .foregroundStyle(.red)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(.ultraThinMaterial)
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
          .opacity(Double(min(1, max(0, -dragX / 90))))
          .padding(6)
      }
      .overlay(alignment: .topTrailing) {
        Text("GOOD")
          .font(.headline)
          .fontWeight(.black)
          .foregroundStyle(.green)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(.ultraThinMaterial)
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
          .opacity(Double(min(1, max(0, dragX / 90))))
          .padding(6)
      }
      .gesture(
        DragGesture()
          .onChanged { value in
            guard !deciding else { return }
            dragX = value.translation.width
          }
          .onEnded { value in
            guard !deciding else { return }
            let x = value.translation.width
            let projected = value.predictedEndTranslation.width
            if x <= -swipeThreshold || projected <= -swipeThreshold {
              deciding = true
              withAnimation(.easeOut(duration: 0.14)) {
                dragX = -420
              }
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                onAgain()
                deciding = false
                dragX = 0
              }
              return
            }
            if x >= swipeThreshold || projected >= swipeThreshold {
              deciding = true
              withAnimation(.easeOut(duration: 0.14)) {
                dragX = 420
              }
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                onGood()
                deciding = false
                dragX = 0
              }
              return
            }
            withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
              dragX = 0
            }
          }
      )
    }
  }
}
