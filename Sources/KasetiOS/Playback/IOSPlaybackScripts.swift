import Foundation

/// iOS-only page scripts, injected next to the shared playback scripts by
/// `SingletonPlayerWebView.installUserScripts` (see docs/ios/spike-findings.md).
enum IOSPlaybackScripts {
    /// Routes the lock-screen next/previous buttons through the shared `REMOTE_NEXT` /
    /// `REMOTE_PREVIOUS` bridge messages (queue-aware, handled by `PlayerService`) instead of
    /// the ±10 s skip buttons iOS shows by default. Runs at document start so the shared
    /// `mediaControlOverrideScript` (document end) sees the flag.
    nonisolated static let nextPreviousBootstrap = """
    (function() {
        window.__kasetUseNextPrev = true;
        try { localStorage.setItem('kasetUseNextPrev', 'true'); } catch (e) {}
    })();
    """

    /// Inaudible `AudioContext` that is never torn down. Without it, pausing and then letting
    /// the screen lock freezes the WebContent process and playback cannot resume.
    /// It is (re)started on `playing` and resumed again whenever the context leaves `running`
    /// or the page changes visibility — pausing in the foreground and then locking suspended the
    /// whole app in the extended spike run when only `playing`/`pause` were handled.
    nonisolated static let keepAlive = """
    (function() {
        if (window.__kasetIOSKeepAlive) return;
        let ctx = null;
        function resume() {
            try { if (ctx && ctx.state !== 'running') { ctx.resume().catch(function() {}); } } catch (e) {}
        }
        function ensure() {
            try {
                if (!ctx) {
                    const AC = window.AudioContext || window.webkitAudioContext;
                    if (!AC) return;
                    ctx = new AC();
                    const gain = ctx.createGain();
                    gain.gain.value = 0.00001;
                    const osc = ctx.createOscillator();
                    osc.frequency.value = 20;
                    osc.connect(gain);
                    gain.connect(ctx.destination);
                    osc.start();
                    ctx.onstatechange = resume;
                }
                resume();
            } catch (e) {}
        }
        window.__kasetIOSKeepAlive = { ensure: ensure };
        document.addEventListener('playing', ensure, true);
        document.addEventListener('pause', resume, true);
        document.addEventListener('visibilitychange', function() { ensure(); }, true);
        window.addEventListener('pageshow', ensure, true);
    })();
    """
}
