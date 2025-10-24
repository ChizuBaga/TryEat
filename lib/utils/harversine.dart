import 'dart:math';

class Harversine{
  double r = 6371;
  double customerLat;
  double customerLon;
  double sellerLat;
  double sellerLon;

  Harversine({
    required this.customerLat, 
    required this.customerLon, 
    required this.sellerLat, 
    required this.sellerLon,
});

  double toRadian(double degree){
    return degree * (pi / 180);
  }

  double radDifferences(double rad1, double rad2){
    return rad2 - rad1;
  }

  double sinnSquare(double sinVal){
    return sinVal * sinVal;
  }

  //Calc distance of 2 points
  double calcDistance (){
    double a = aTerm(customerLat, customerLon, sellerLat, sellerLon);
    return r * calcC(a);
  }
  
  //c-term calculation
  double calcC(double a){
    return 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  //a-term calculation
  double aTerm(customerLat, customerLon, sellerLat, sellerLon){
    double latRad = toRadian(customerLat);
    double lonRad = toRadian(customerLon);
    double latRad2 = toRadian(sellerLat);
    double lonRad2 = toRadian(sellerLon);

    //Calc Differences
    double radDiff1 = radDifferences(latRad, latRad2);
    double radDiff2 = radDifferences(lonRad, lonRad2);

    double a = sinnSquare((radDiff1) / 2) + cos(latRad) * cos(latRad2) * sinnSquare(radDiff2 / 2);
    return a;
  }

}