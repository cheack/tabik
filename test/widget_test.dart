import 'package:flutter_test/flutter_test.dart';
import 'package:tabik/main.dart';

void main() {
  test('siteIndexAfterRemoval selects previous tab when available', () {
    expect(siteIndexAfterRemoval(2), 1);
    expect(siteIndexAfterRemoval(1), 0);
  });

  test('siteIndexAfterRemoval keeps zero for first or last remaining tab', () {
    expect(siteIndexAfterRemoval(0), 0);
  });
}
