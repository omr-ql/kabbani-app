import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../models/reservation.dart';
import '../../services/api_service.dart';

class AdminReservationsWidget extends StatefulWidget {
  const AdminReservationsWidget({Key? key}) : super(key: key);

  @override
  State<AdminReservationsWidget> createState() =>
      _AdminReservationsWidgetState();
}

class _AdminReservationsWidgetState extends State<AdminReservationsWidget> {
  List<Reservation> _reservations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filter = 'active';

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
        throw Exception('Not authenticated');
      }

      final reservations = await ApiService.getAllReservations(token);

      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fulfillReservation(String reservationId) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final success = await ApiService.fulfillReservation(token, reservationId);

      if (success['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.markedAsFulfilled),
            backgroundColor: Colors.green,
          ),
        );
        _loadReservations();
      } else {
        throw Exception('Failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: Color(0xFFFF4B4B),
        ),
      );
    }
  }

  List<Reservation> get _filteredReservations {
    switch (_filter) {
      case 'active':
        return _reservations.where((r) => !r.isFulfilled).toList();
      case 'fulfilled':
        return _reservations.where((r) => r.isFulfilled).toList();
      default:
        return _reservations;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFFF4B4B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_note,
                  color: Color(0xFFFF4B4B),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                l10n.reservations,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.grey[400]),
                onPressed: _loadReservations,
                tooltip: l10n.retry,
              ),
            ],
          ),
          SizedBox(height: 15),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label:
                      '${l10n.active} (${_reservations.where((r) => !r.isFulfilled).length})',
                  isSelected: _filter == 'active',
                  onTap: () => setState(() => _filter = 'active'),
                ),
                SizedBox(width: 8),
                _FilterChip(
                  label:
                      '${l10n.fulfilled} (${_reservations.where((r) => r.isFulfilled).length})',
                  isSelected: _filter == 'fulfilled',
                  onTap: () => setState(() => _filter = 'fulfilled'),
                ),
                SizedBox(width: 8),
                _FilterChip(
                  label: '${l10n.all} (${_reservations.length})',
                  isSelected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
              ],
            ),
          ),
          SizedBox(height: 15),

          // Content
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: _isLoading
                ? _buildLoadingView()
                : _errorMessage != null
                ? _buildErrorView()
                : _filteredReservations.isEmpty
                ? _buildEmptyView()
                : _buildReservationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFFF4B4B)),
            SizedBox(height: 12),
            Text(l10n.loading, style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Color(0xFFFF4B4B)),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey[600]),
            SizedBox(height: 12),
            Text(
              _filter == 'active'
                  ? l10n.noActiveReservations
                  : _filter == 'fulfilled'
                  ? l10n.noFulfilledReservations
                  : l10n.noReservationsYet,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationsList() {
    return Container(
      constraints: BoxConstraints(maxHeight: 400),
      child: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: _filteredReservations.length,
        separatorBuilder: (context, index) =>
            Divider(color: Colors.grey[800], height: 24),
        itemBuilder: (context, index) {
          final reservation = _filteredReservations[index];
          return _AdminReservationCard(
            reservation: reservation,
            onFulfill: () => _fulfillReservation(reservation.id),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFFF4B4B) : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFFFF4B4B) : Colors.grey[700]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _AdminReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onFulfill;

  const _AdminReservationCard({
    required this.reservation,
    required this.onFulfill,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final isPast = reservation.pickupDate.isBefore(now);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              CircleAvatar(
                backgroundColor: reservation.isFulfilled
                    ? Colors.green
                    : isPast
                    ? Colors.orange
                    : Color(0xFFFF4B4B),
                radius: 20,
                child: Text(
                  reservation.customerName[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.productName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${reservation.customerName} • ${l10n.quantity}: ${reservation.quantity}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: reservation.isFulfilled
                      ? Colors.green.withOpacity(0.2)
                      : isPast
                      ? Colors.orange.withOpacity(0.2)
                      : Color(0xFFFF4B4B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  reservation.isFulfilled
                      ? l10n.done
                      : isPast
                      ? l10n.past
                      : l10n.active,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: reservation.isFulfilled
                        ? Colors.green
                        : isPast
                        ? Colors.orange
                        : Color(0xFFFF4B4B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Details
          _InfoRow(
            icon: Icons.phone,
            label: l10n.contact,
            value: reservation.customerContact,
          ),
          _InfoRow(
            icon: Icons.event,
            label: l10n.pickup,
            value: DateFormat(
              'MMM dd, yyyy - hh:mm a',
            ).format(reservation.pickupDate),
          ),
          _InfoRow(
            icon: Icons.schedule,
            label: l10n.reservedOn(
              DateFormat('MMM dd').format(reservation.createdAt),
            ),
            value: '',
          ),

          if (reservation.notes != null && reservation.notes!.isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 14, color: Colors.grey[500]),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reservation.notes!,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Button
          if (!reservation.isFulfilled) ...[
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onFulfill,
                icon: Icon(Icons.check_circle, size: 18),
                label: Text(l10n.markAsFulfilled),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          SizedBox(width: 8),
          if (value.isNotEmpty) ...[
            Text(
              '$label: ',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(fontSize: 12, color: Colors.grey[300]),
              ),
            ),
          ] else
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[300]),
              ),
            ),
        ],
      ),
    );
  }
}
