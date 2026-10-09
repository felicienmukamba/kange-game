/// Estimates the offset between this device's clock and the server's, so that
/// countdowns driven by server timestamps (`endsAt`, `serverTime`) are fair even
/// when the phone's clock is wrong.
///
/// Uses the smallest observed offset sample: network delay only ever makes the
/// server timestamp look older, so the minimum is the best estimate.
class ServerClock {
  ServerClock({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  int? _offsetMs;
  int _samples = 0;

  /// Feed a server timestamp (epoch ms) from a message that was just received.
  void sample(int serverTimeMs) {
    final offset = serverTimeMs - _now().millisecondsSinceEpoch;
    // Keep the most generous estimate but let it drift back after many samples.
    if (_offsetMs == null || offset > _offsetMs! || _samples > 50) {
      _offsetMs = offset;
      _samples = 0;
    }
    _samples++;
  }

  int get offsetMs => _offsetMs ?? 0;

  /// Current server time in epoch milliseconds.
  int nowMs() => _now().millisecondsSinceEpoch + offsetMs;

  /// Time left until a server deadline (never negative).
  Duration until(int serverDeadlineMs) {
    final left = serverDeadlineMs - nowMs();
    return Duration(milliseconds: left < 0 ? 0 : left);
  }
}
