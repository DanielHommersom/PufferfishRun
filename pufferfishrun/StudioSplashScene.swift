//
//  StudioSplashScene.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 08/05/2026.
//

import SpriteKit
import WebKit

class StudioSplashScene: SKScene {

    private var webView: WKWebView?

    // MARK: - didMove
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(
            red: 0.06, green: 0.04, blue: 0.10, alpha: 1.0)

        setupWebLogo(in: view)
        scheduleTransition()
    }

    // MARK: - SVG Logo via WKWebView
    private func setupWebLogo(in skView: SKView) {

        // The exact SVG from DigitalDiamonds-Logo.svg
        // embedded as an HTML string
        let svgContent = """
        <svg xmlns="http://www.w3.org/2000/svg"
             viewBox="55 0 584 280"
             font-family="'Arial Black','Helvetica Neue',Arial,sans-serif">
          <defs>
            <linearGradient id="g1" x1="0%" y1="0%"
              x2="100%" y2="100%">
              <stop offset="0%" stop-color="#7C3AED"/>
              <stop offset="50%" stop-color="#3B82F6"/>
              <stop offset="100%" stop-color="#22D3EE"/>
            </linearGradient>
            <linearGradient id="g2" x1="0%" y1="0%"
              x2="100%" y2="100%">
              <stop offset="0%" stop-color="#A78BFA"/>
              <stop offset="100%" stop-color="#60A5FA"/>
            </linearGradient>
            <linearGradient id="g3" x1="0%" y1="0%"
              x2="100%" y2="100%">
              <stop offset="0%" stop-color="#4C1D95"/>
              <stop offset="100%" stop-color="#1D4ED8"/>
            </linearGradient>
            <linearGradient id="g4" x1="0%" y1="0%"
              x2="100%" y2="100%">
              <stop offset="0%" stop-color="#3B82F6"/>
              <stop offset="100%" stop-color="#22D3EE"/>
            </linearGradient>
            <linearGradient id="textGrad" x1="0%" y1="0%"
              x2="100%" y2="0%">
              <stop offset="0%" stop-color="#7C3AED"/>
              <stop offset="50%" stop-color="#3B82F6"/>
              <stop offset="100%" stop-color="#22D3EE"/>
            </linearGradient>
          </defs>
          <polygon points="105,90 175,70 120,120"
            fill="url(#g2)" opacity="0.9"/>
          <polygon points="105,90 85,140 120,120"
            fill="#5B21B6" opacity="0.9"/>
          <polygon points="175,70 210,120 120,120"
            fill="url(#g1)" opacity="0.95"/>
          <polygon points="175,70 245,90 210,120"
            fill="url(#g2)" opacity="0.75"/>
          <polygon points="245,90 265,140 210,120"
            fill="url(#g4)" opacity="0.85"/>
          <polygon points="85,140 120,120 175,255"
            fill="#1E1B4B" opacity="0.95"/>
          <polygon points="120,120 210,120 175,255"
            fill="url(#g3)" opacity="0.9"/>
          <polygon points="210,120 265,140 175,255"
            fill="#1D4ED8" opacity="0.85"/>
          <polygon points="85,140 175,255 265,140"
            fill="url(#g1)" opacity="0.15"/>
          <polygon points="105,90 85,140 120,120 175,70"
            fill="none"
            stroke="rgba(167,139,250,0.3)"
            stroke-width="0.5"/>
          <polygon points="245,90 265,140 210,120 175,70"
            fill="none"
            stroke="rgba(96,165,250,0.3)"
            stroke-width="0.5"/>
          <ellipse cx="175" cy="258" rx="50" ry="7"
            fill="#3B82F6" opacity="0.18"/>
          <text x="305" y="130" fill="#F8FAFC"
            font-size="52" font-weight="900"
            letter-spacing="-0.5"
            dominant-baseline="middle">DIGITAL</text>
          <text x="305" y="194"
            fill="url(#textGrad)"
            font-size="52" font-weight="900"
            letter-spacing="-0.5"
            dominant-baseline="middle">DIAMONDS</text>
        </svg>
        """

        // Wrap SVG in HTML with transparent background
        // and centered layout
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport"
          content="width=device-width,
                   initial-scale=1.0,
                   maximum-scale=1.0">
        <style>
          * { margin:0; padding:0; box-sizing:border-box; }
          html, body {
            width:100%; height:100%;
            background:transparent;
            display:flex;
            align-items:center;
            justify-content:center;
            overflow:hidden;
          }
          svg {
            width:90%;
            max-width:500px;
            height:auto;
          }
        </style>
        </head>
        <body>
        \(svgContent)
        </body>
        </html>
        """

        // Create WKWebView configuration
        // with transparent background
        let config = WKWebViewConfiguration()
        let webView = WKWebView(
            frame: skView.bounds,
            configuration: config
        )
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.alpha = 0
        webView.isUserInteractionEnabled = false

        // Load HTML
        webView.loadHTMLString(html, baseURL: nil)

        // Add as subview on top of SKView
        skView.addSubview(webView)
        self.webView = webView

        // Animate in after short delay
        // (allow WebView to render first)
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.4
        ) {
            UIView.animate(
                withDuration: 0.6,
                delay: 0,
                options: .curveEaseOut
            ) {
                webView.alpha = 1.0
            }
        }
    }

    // MARK: - Transition
    private func scheduleTransition() {
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.8),
            SKAction.run { [weak self] in
                self?.transitionToSplash()
            }
        ]))
    }

    private func transitionToSplash() {
        // Fade out WebView first
        guard let skView = view else { return }
        UIView.animate(
            withDuration: 0.5,
            animations: {
                self.webView?.alpha = 0
            },
            completion: { _ in
                self.webView?.removeFromSuperview()
                self.webView = nil
                let scene = SplashScene(size: self.size)
                scene.scaleMode = self.scaleMode
                skView.presentScene(scene,
                                   transition: SKTransition.fade(
                                    withDuration: 0.3))
            }
        )
    }

    // MARK: - Cleanup on scene exit
    override func willMove(from view: SKView) {
        webView?.removeFromSuperview()
        webView = nil
    }

    // MARK: - Touch to skip
    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        removeAllActions()
        transitionToSplash()
    }
}

