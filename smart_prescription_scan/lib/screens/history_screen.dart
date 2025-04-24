import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../constants/app_constants.dart';
import '../models/prescription_model.dart';
import '../services/storage_service.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storageService = StorageService();
  List<PrescriptionModel> _allScans = [];
  List<PrescriptionModel> _filteredScans = [];
  String _searchQuery = '';
  bool _showImportantOnly = false;
  bool _sortByNewest = true; // true for newest first, false for oldest first
  
  @override
  void initState() {
    super.initState();
    _loadScans();
  }
  
  void _loadScans() {
    _allScans = _storageService.getAllPrescriptions();
    _filterAndSortScans();
  }
  
  void _filterAndSortScans() {
    // Filter by search query
    List<PrescriptionModel> filtered = _allScans;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((scan) => 
        scan.summary.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Filter by importance
    if (_showImportantOnly) {
      filtered = filtered.where((scan) => scan.isImportant).toList();
    }
    
    // Sort by date
    filtered.sort((a, b) {
      if (_sortByNewest) {
        return b.dateScanned.compareTo(a.dateScanned);
      } else {
        return a.dateScanned.compareTo(b.dateScanned);
      }
    });
    
    setState(() {
      _filteredScans = filtered;
    });
  }
  
  void _toggleSortOrder() {
    setState(() {
      _sortByNewest = !_sortByNewest;
    });
    _filterAndSortScans();
  }
  
  void _toggleImportantFilter() {
    setState(() {
      _showImportantOnly = !_showImportantOnly;
    });
    _filterAndSortScans();
  }
  
  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterAndSortScans();
  }
  
  void _deleteScan(PrescriptionModel scan) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scan'),
        content: const Text('Are you sure you want to delete this scan? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _storageService.deletePrescription(scan.id);
      _loadScans();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan deleted')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.history),
        actions: [
          // Sort order toggle
          IconButton(
            icon: Icon(_sortByNewest ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: _toggleSortOrder,
            tooltip: _sortByNewest ? 'Newest first' : 'Oldest first',
          ),
          
          // Important only toggle
          IconButton(
            icon: Icon(
              Icons.star,
              color: _showImportantOnly ? AppColors.warning : null,
            ),
            onPressed: _toggleImportantFilter,
            tooltip: _showImportantOnly ? 'Show all' : 'Show important only',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: TextField(
              onChanged: _updateSearchQuery,
              decoration: const InputDecoration(
                hintText: AppStrings.search,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          
          // Status bar (number of results)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredScans.length} ${_filteredScans.length == 1 ? 'result' : 'results'}',
                  style: AppTextStyles.caption,
                ),
                if (_showImportantOnly)
                  OutlinedButton.icon(
                    onPressed: _toggleImportantFilter,
                    icon: const Icon(Icons.star, size: 16),
                    label: const Text('Important only'),
                  ),
              ],
            ),
          ),
          
          // Prescription list
          Expanded(
            child: _filteredScans.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredScans.length,
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    itemBuilder: (context, index) {
                      final scan = _filteredScans[index];
                      return _buildScanItem(scan);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            _searchQuery.isEmpty
                ? AppStrings.noHistory
                : 'No results found for "$_searchQuery"',
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScanItem(PrescriptionModel scan) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(prescription: scan),
            ),
          ).then((_) => _loadScans());
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Row(
            children: [
              // Image preview
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: _buildImagePreview(scan),
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              
              // Scan info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and important indicator
                    Row(
                      children: [
                        Text(
                          _formatDate(scan.dateScanned),
                          style: AppTextStyles.caption,
                        ),
                        if (scan.isImportant) ...[
                          const SizedBox(width: AppDimensions.paddingS),
                          const Icon(
                            Icons.star,
                            color: AppColors.warning,
                            size: AppDimensions.iconSizeS,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Summary preview
                    Text(
                      _getSummaryPreview(scan.summary),
                      style: AppTextStyles.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteScan(scan),
                color: AppColors.error,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildImagePreview(PrescriptionModel scan) {
    if (kIsWeb) {
      // On web, use a placeholder since we can't access local files
      return Container(
        color: AppColors.cardBackground,
        child: const Icon(
          Icons.description,
          color: AppColors.primaryBlue,
          size: 40,
        ),
      );
    } else {
      // On mobile platforms, use File
      return Image.file(
        File(scan.imagePath),
        fit: BoxFit.cover,
      );
    }
  }
  
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final scanDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (scanDate == today) {
      return 'Today, ${DateFormat.jm().format(dateTime)}';
    } else if (scanDate == yesterday) {
      return 'Yesterday, ${DateFormat.jm().format(dateTime)}';
    } else {
      return DateFormat.yMMMd().format(dateTime);
    }
  }
  
  String _getSummaryPreview(String summary) {
    // Return first 100 characters as preview
    if (summary.length > 100) {
      return '${summary.substring(0, 100)}...';
    }
    return summary;
  }
} 