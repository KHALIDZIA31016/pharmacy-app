import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/supplier_viewmodel.dart';
import '../../widgets/doctor_card.dart';
import '../../widgets/empty_state.dart';

/// Every doctor / pharmacist registered in the app.
class AllDoctorsScreen extends StatelessWidget {
  const AllDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SupplierViewModel>();
    final uid = context.read<AuthViewModel>().user?.uid ?? '';
    final people = vm.filteredBuyers;
    final doctors = vm.buyers
        .where((b) => !b.isSupplier && b.profession != Profession.pharmacist)
        .length;
    final pharmacists = vm.buyers.length - doctors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Hero header with search
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your clients',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Doctors & pharmacists',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _pill(
                        Icons.medical_services_outlined,
                        '$doctors doctors',
                      ),
                      const SizedBox(width: 8),
                      _pill(
                        Icons.local_pharmacy_outlined,
                        '$pharmacists pharmacists',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: vm.setDoctorQuery,
                    decoration: InputDecoration(
                      hintText: 'Search name or clinic',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => vm.load(uid),
                child: people.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 80),
                          EmptyState(
                            icon: Icons.medical_services_outlined,
                            title: 'No doctors found',
                            message:
                                'Doctors and pharmacists who sign up will appear here.',
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: people.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (_, i) => DoctorCard(
                          person: people[i],
                          orders: vm.ordersFrom(people[i].uid),
                          spent: vm.spentBy(people[i].uid),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
