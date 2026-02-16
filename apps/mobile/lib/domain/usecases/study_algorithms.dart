int nextIntervalDays({
  required int currentInterval,
  required bool good,
}) {
  if (!good) {
    return 1;
  }

  return currentInterval < 2 ? 2 : currentInterval * 2;
}
