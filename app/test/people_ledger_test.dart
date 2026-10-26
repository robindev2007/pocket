import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:manage_money/data/models/debt_model.dart';
import 'package:manage_money/data/models/person_debt_model.dart';
import 'package:manage_money/features/tracker/controllers/tracker_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.testMode = true;
  });

  group('People & Ledger TrackerController Tests', () {
    test('peopleSummaries correctly aggregates and calculates net balance for each person', () {
      final controller = Get.put(TrackerController());

      controller.people.assignAll(['Tanvir', 'Rahim', 'Ayesha']);

      controller.debts.assignAll([
        // Tanvir: lent 1000, repaid 400 -> owes 600
        DebtModel(
          id: 'd-1',
          personName: 'Tanvir',
          title: 'Dinner buffet',
          amount: 1000.0,
          date: DateTime.parse('2026-10-25T12:00:00Z'),
          direction: DebtDirection.theyOweMe,
          repayments: [
            DebtRepaymentModel(
              id: 'r-1',
              amount: 400.0,
              date: DateTime.parse('2026-10-26T12:00:00Z'),
            ),
          ],
        ),
        // Rahim: borrowed 500, no repayment -> user owes 500
        DebtModel(
          id: 'd-2',
          personName: 'Rahim',
          title: 'Uber share',
          amount: 500.0,
          date: DateTime.parse('2026-10-24T12:00:00Z'),
          direction: DebtDirection.iOweThem,
          repayments: [],
        ),
        // Ayesha: lent 300, repaid 300 -> settled
        DebtModel(
          id: 'd-3',
          personName: 'Ayesha',
          title: 'Coffee',
          amount: 300.0,
          date: DateTime.parse('2026-10-23T12:00:00Z'),
          direction: DebtDirection.theyOweMe,
          repayments: [
            DebtRepaymentModel(
              id: 'r-2',
              amount: 300.0,
              date: DateTime.parse('2026-10-24T12:00:00Z'),
            ),
          ],
        ),
      ]);

      final summaries = controller.peopleSummaries;
      expect(summaries.length, 3);

      final tanvir = summaries.firstWhere((p) => p.name == 'Tanvir');
      expect(tanvir.theyOweMe, 600.0);
      expect(tanvir.iOweThem, 0.0);
      expect(tanvir.netBalance, 600.0);
      expect(tanvir.theyOweUser, isTrue);
      expect(tanvir.activeDebtsCount, 1);
      expect(tanvir.settledDebtsCount, 0);

      final rahim = summaries.firstWhere((p) => p.name == 'Rahim');
      expect(rahim.theyOweMe, 0.0);
      expect(rahim.iOweThem, 500.0);
      expect(rahim.netBalance, -500.0);
      expect(rahim.userOwesThem, isTrue);
      expect(rahim.activeDebtsCount, 1);

      final ayesha = summaries.firstWhere((p) => p.name == 'Ayesha');
      expect(ayesha.theyOweMe, 0.0);
      expect(ayesha.iOweThem, 0.0);
      expect(ayesha.netBalance, 0.0);
      expect(ayesha.isSettled, isTrue);
      expect(ayesha.settledDebtsCount, 1);
    });

    test('getPersonLedger generates chronological statement history', () {
      final controller = Get.put(TrackerController());

      controller.debts.assignAll([
        DebtModel(
          id: 'd-1',
          personName: 'Tanvir',
          title: 'Dinner bill',
          amount: 1000.0,
          date: DateTime.parse('2026-10-25T12:00:00Z'),
          direction: DebtDirection.theyOweMe,
          repayments: [
            DebtRepaymentModel(
              id: 'r-1',
              amount: 400.0,
              date: DateTime.parse('2026-10-26T12:00:00Z'),
            ),
          ],
        ),
      ]);

      final ledger = controller.getPersonLedger('Tanvir');
      expect(ledger.length, 2);

      // Newest item first
      expect(ledger[0].type, PersonLedgerType.repaymentCollected);
      expect(ledger[0].amount, 400.0);

      // Older item second
      expect(ledger[1].type, PersonLedgerType.loanGiven);
      expect(ledger[1].amount, 1000.0);
    });

    test('settleAllDebtsForPerson records full repayments for all active loans', () async {
      final controller = Get.put(TrackerController());

      controller.debts.assignAll([
        DebtModel(
          id: 'd-1',
          personName: 'Siam',
          title: 'Movie tickets',
          amount: 600.0,
          date: DateTime.now(),
          direction: DebtDirection.theyOweMe,
          repayments: [],
        ),
        DebtModel(
          id: 'd-2',
          personName: 'Siam',
          title: 'Popcorn',
          amount: 400.0,
          date: DateTime.now(),
          direction: DebtDirection.theyOweMe,
          repayments: [],
        ),
      ]);

      expect(controller.getPersonSummary('Siam').theyOweMe, 1000.0);

      await controller.settleAllDebtsForPerson('Siam');

      final updated = controller.getPersonSummary('Siam');
      expect(updated.theyOweMe, 0.0);
      expect(updated.isSettled, isTrue);
      expect(updated.settledDebtsCount, 2);
    });
  });
}
