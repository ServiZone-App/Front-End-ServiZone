
enum BookingPeriod { last3Months, last6Months, last9Months, all }

class BookingFilterService {
  static String getPeriodLabel(BookingPeriod period) {
    switch (period) {
      case BookingPeriod.last3Months:
        return 'Últimos 3 meses';
      case BookingPeriod.last6Months:
        return 'Últimos 6 meses';
      case BookingPeriod.last9Months:
        return 'Últimos 9 meses';
      case BookingPeriod.all:
        return 'Todas las reservas';
    }
  }

  static DateTime? getStartDate(BookingPeriod period) {
    if (period == BookingPeriod.all) return null;
    
    final now = DateTime.now().toUtc();
    int months;
    
    switch (period) {
      case BookingPeriod.last3Months:
        months = 3;
        break;
      case BookingPeriod.last6Months:
        months = 6;
        break;
      case BookingPeriod.last9Months:
        months = 9;
        break;
      case BookingPeriod.all:
        return null;
    }
    
    // Calcular fecha de inicio restando meses
    return DateTime(now.year, now.month - months, now.day).toUtc();
  }

  static bool isWithinPeriod(DateTime bookingDate, BookingPeriod period) {
    if (period == BookingPeriod.all) return true;
    
    final startDate = getStartDate(period);
    if (startDate == null) return true;
    
    // Comparar fechas en UTC
    final bookingUtc = bookingDate.toUtc();
    return bookingUtc.isAfter(startDate);
  }
}


