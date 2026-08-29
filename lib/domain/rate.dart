/// Percentage handling for the domain layer.
///
/// Rates follow the same rule as money: they are integers inside the domain.
/// A rate typed as "7.25%" is stored as 725 basis points, never as 0.0725,
/// so that two inputs that look identical to the user are identical to the
/// engine.
library;

/// An integer number of basis points. 10000 basis points == 100%.
typedef BasisPoints = int;

/// Basis points in one percent.
const int basisPointsPerPercent = 100;

/// Basis points in 100%.
const int basisPointsPerUnit = 10000;

/// Converts a percentage from the outside world into basis points.
///
/// 7 => 700, 7.25 => 725, 0.5 => 50.
BasisPoints percentToBasisPoints(num percent) =>
    (percent * basisPointsPerPercent).round();

/// Converts basis points to the percentage a user reads. Display layer only.
double basisPointsToPercent(BasisPoints bps) => bps / basisPointsPerPercent;

/// Converts basis points to the decimal rate the engine compounds with.
///
/// 700 => 0.07. This is the one place basis points become a double, and it
/// happens on the way *into* a calculation, never on the way out.
double basisPointsToRate(BasisPoints bps) => bps / basisPointsPerUnit;
