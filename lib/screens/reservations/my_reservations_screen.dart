import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../models/reservation.dart';
import '../../services/api_service.dart';
import '../../utils/message_helper.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({Key? key}) : super(key: key);

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  List<Reservation> _reservations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');

      if (token == null) {
        setState(() {
          _errorMessage = 'errorNotAuthenticated';
          _isLoading = false;
        });
        return;
      }

      final reservations = await ApiService.getMyReservations(token);

      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'errorConnection';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelReservation(String reservationId) async {
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.cancelReservationQuestion,
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.sureToCancel,
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no, style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.cancelReservation,
              style: TextStyle(color: Color(0xFFFF4B4B)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');

      if (token == null) {
        MessageHelper.showMessage(
          context,
          'errorNotAuthenticated',
          isError: true,
        );
        return;
      }

      final response = await ApiService.cancelReservation(token, reservationId);

      if (!mounted) return;

      if (response['success'] == true) {
        MessageHelper.showMessage(
          context,
          'successReservationCancelled',
          isError: false,
        );
        _loadReservations();
      } else {
        MessageHelper.showApiResponse(context, response);
      }
    } catch (e) {
      if (!mounted) return;
      MessageHelper.showMessage(context, 'errorConnection', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.myReservations, style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFFFF4B4B),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadReservations,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFFF4B4B)))
          : _errorMessage != null
          ? _buildErrorView()
          : _reservations.isEmpty
          ? _buildEmptyView()
          : RefreshIndicator(
              onRefresh: _loadReservations,
              color: Color(0xFFFF4B4B),
              child: ListView.builder(
                padding: EdgeInsets.all(20),
                itemCount: _reservations.length,
                itemBuilder: (context, index) {
                  final reservation = _reservations[index];
                  return _ReservationCard(
                    reservation: reservation,
                    onCancel: () => _cancelReservation(reservation.id!),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildErrorView() {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Color(0xFFFF4B4B)),
            SizedBox(height: 20),
            Text(
              MessageHelper.getMessage(context, _errorMessage!),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadReservations,
              icon: Icon(Icons.refresh),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF4B4B),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[700]),
          SizedBox(height: 20),
          Text(
            l10n.noReservationsYet,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            l10n.yourReservationsAppearHere,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onCancel;

  const _ReservationCard({required this.reservation, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final isPast = reservation.pickupDate.isBefore(now);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: reservation.isFulfilled
                      ? Colors.green.withOpacity(0.2)
                      : isPast
                      ? Colors.orange.withOpacity(0.2)
                      : Color(0xFFFF4B4B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: reservation.isFulfilled
                        ? Colors.green
                        : isPast
                        ? Colors.orange
                        : Color(0xFFFF4B4B),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      reservation.isFulfilled
                          ? Icons.check_circle
                          : isPast
                          ? Icons.warning
                          : Icons.schedule,
                      size: 14,
                      color: reservation.isFulfilled
                          ? Colors.green
                          : isPast
                          ? Colors.orange
                          : Color(0xFFFF4B4B),
                    ),
                    SizedBox(width: 4),
                    Text(
                      reservation.isFulfilled
                          ? l10n.fulfilled
                          : isPast
                          ? l10n.pastDue
                          : l10n.active,
                      style: TextStyle(
                        color: reservation.isFulfilled
                            ? Colors.green
                            : isPast
                            ? Colors.orange
                            : Color(0xFFFF4B4B),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Text(
                DateFormat('MMM dd, yyyy').format(reservation.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Product Name
          Text(
            reservation.productName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),

          // Details
          _DetailRow(
            icon: Icons.shopping_cart,
            label: l10n.quantity,
            value: '${reservation.quantity}',
          ),
          _DetailRow(
            icon: Icons.person,
            label: l10n.name,
            value: reservation.customerName,
          ),
          _DetailRow(
            icon: Icons.phone,
            label: l10n.contact,
            value: reservation.customerContact,
          ),
          _DetailRow(
            icon: Icons.event,
            label: l10n.pickup,
            value: DateFormat(
              'MMM dd, yyyy - hh:mm a',
            ).format(reservation.pickupDate),
          ),

          if (reservation.notes != null && reservation.notes!.isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[400]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reservation.notes!,
                      style: TextStyle(color: Colors.grey[300], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Cancel Button
          if (!reservation.isFulfilled && !isPast) ...[
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: Icon(Icons.cancel, color: Color(0xFFFF4B4B)),
                label: Text(
                  l10n.cancelReservation,
                  style: TextStyle(color: Color(0xFFFF4B4B)),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFFFF4B4B)),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
