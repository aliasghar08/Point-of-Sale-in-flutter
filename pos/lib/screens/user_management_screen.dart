import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:pos/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:pos/providers/settings_provider.dart';
import 'package:pos/services/auth_service.dart';
import 'package:pos/widgets/role_guard.dart';
import 'package:pos/models/user.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleGuard(
      allowedRoles: ['owner'],
      child: _UserManagementContent(),
    );
  }
}

class _UserManagementContent extends StatefulWidget {
  const _UserManagementContent({super.key});

  @override
  State<_UserManagementContent> createState() => _UserManagementContentState();
}

class _UserManagementContentState extends State<_UserManagementContent> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _hasPermission = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkUserPermissions();
  }

  // ========== CHECK USER PERMISSIONS ==========
  Future<void> _checkUserPermissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasPermission = false;
    });

    try {
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'No user logged in';
          _isLoading = false;
        });
        return;
      }

      final appUser = await _authService.getCurrentUserData();
      
      if (appUser != null && appUser.role == 'owner') {
        setState(() {
          _hasPermission = true;
          _errorMessage = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'You need owner permissions to manage users. Your role: ${appUser?.role ?? 'unknown'}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error checking permissions: $e');
      setState(() {
        _errorMessage = 'Error checking permissions: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(      
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              ),
            )
          : _errorMessage != null
              ? _buildErrorScreen(isDarkMode)
              : _hasPermission
                  ? _buildUserList(isDarkMode)
                  : _buildPermissionDeniedScreen(isDarkMode),
    );
  }

  // ========== PERMISSION DENIED SCREEN ==========
  Widget _buildPermissionDeniedScreen(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: isDarkMode ? Colors.red.shade400 : Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need owner permissions to access this screen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checkUserPermissions,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== ERROR SCREEN ==========
  Widget _buildErrorScreen(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: isDarkMode ? Colors.red.shade400 : Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _checkUserPermissions,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== USER LIST ==========
  Widget _buildUserList(bool isDarkMode) {
    return FutureBuilder<List<AppUser>>(
      future: _authService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('❌ Error loading users: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: isDarkMode ? Colors.red.shade400 : Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading users',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Could not load user list. Please check your permissions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDarkMode ? Colors.white : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first user',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddUserDialog(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return InkWell(
              onTap: () => _showUserDetailsDialog(context, user, isDarkMode),
              borderRadius: BorderRadius.circular(12),
              child: _buildUserCard(context, user, isDarkMode),
            );
          },
        );
      },
    );
  }

  // ========== USER CARD ==========
  Widget _buildUserCard(BuildContext context, AppUser user, bool isDarkMode) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isCurrentUser = authProvider.currentUser?.id == user.id;

    final initial = user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: user.isActive
                  ? (isDarkMode ? Colors.green.shade900 : Colors.green.shade100)
                  : (isDarkMode ? Colors.red.shade900 : Colors.red.shade100),
              child: Text(
                initial,
                style: TextStyle(
                  color: user.isActive
                      ? (isDarkMode ? Colors.green.shade400 : Colors.green)
                      : (isDarkMode ? Colors.red.shade400 : Colors.red),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  if (user.phone.isNotEmpty)
                    Text(
                      user.phone,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role, isDarkMode).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.roleDisplay,
                          style: TextStyle(
                            color: _getRoleColor(user.role, isDarkMode),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!user.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.red.shade900.withOpacity(0.5)
                                : Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Inactive',
                            style: TextStyle(
                              color: isDarkMode ? Colors.red.shade400 : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.blue.shade900.withOpacity(0.5)
                                : Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'You',
                            style: TextStyle(
                              color: isDarkMode ? Colors.blue.shade400 : Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (user.businessId != null && user.businessId!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.purple.shade900.withOpacity(0.5)
                                : Colors.purple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.business,
                                size: 10,
                                color: isDarkMode ? Colors.purple.shade400 : Colors.purple,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Business',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.purple.shade400 : Colors.purple,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isCurrentUser)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditUserDialog(context, user);
                      break;
                    case 'toggle':
                      _toggleUserActive(context, user);
                      break;
                    case 'delete':
                      _deleteUser(context, user);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          size: 20,
                          color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Edit Role',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          user.isActive ? Icons.block : Icons.check_circle,
                          size: 20,
                          color: user.isActive
                              ? (isDarkMode ? Colors.red.shade400 : Colors.red)
                              : (isDarkMode ? Colors.green.shade400 : Colors.green),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.isActive ? 'Deactivate' : 'Activate',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          size: 20,
                          color: isDarkMode ? Colors.red.shade400 : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: isDarkMode ? Colors.red.shade400 : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ========== USER DETAILS DIALOG ==========
  void _showUserDetailsDialog(BuildContext context, AppUser user, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: user.isActive
                  ? (isDarkMode ? Colors.green.shade900 : Colors.green.shade100)
                  : (isDarkMode ? Colors.red.shade900 : Colors.red.shade100),
              radius: 24,
              child: Text(
                user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : 'U',
                style: TextStyle(
                  color: user.isActive
                      ? (isDarkMode ? Colors.green.shade400 : Colors.green)
                      : (isDarkMode ? Colors.red.shade400 : Colors.red),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    user.roleDisplay,
                    style: TextStyle(
                      fontSize: 14,
                      color: user.isActive
                          ? (isDarkMode ? Colors.green.shade400 : Colors.green)
                          : (isDarkMode ? Colors.red.shade400 : Colors.red),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem(
                icon: Icons.email,
                label: 'Email',
                value: user.email,
                isDarkMode: isDarkMode,
              ),
              _buildDetailItem(
                icon: Icons.phone,
                label: 'Phone',
                value: user.phone.isEmpty ? 'Not provided' : user.phone,
                isDarkMode: isDarkMode,
              ),
              _buildDetailItem(
                icon: Icons.business,
                label: 'Business ID',
                value: user.businessId?.isEmpty ?? true ? 'Not assigned' : user.businessId!,
                isDarkMode: isDarkMode,
              ),
              _buildDetailItem(
                icon: Icons.calendar_today,
                label: 'Joined',
                value: DateFormat('dd MMM yyyy, hh:mm a').format(user.createdAt),
                isDarkMode: isDarkMode,
              ),
              _buildDetailItem(
                icon: Icons.person,
                label: 'User ID',
                value: user.id,
                isDarkMode: isDarkMode,
                isCode: true,
              ),
              _buildDetailItem(
                icon: user.isActive ? Icons.check_circle : Icons.block,
                label: 'Status',
                value: user.isActive ? 'Active' : 'Inactive',
                isDarkMode: isDarkMode,
                valueColor: user.isActive
                    ? (isDarkMode ? Colors.green.shade400 : Colors.green)
                    : (isDarkMode ? Colors.red.shade400 : Colors.red),
              ),
              _buildDetailItem(
                icon: Icons.security,
                label: 'Permissions',
                value: _getPermissionsList(user),
                isDarkMode: isDarkMode,
                isMultiline: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          if (user.role != 'owner')
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showEditUserDialog(context, user);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Role'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  // ========== DETAIL ITEM ==========
  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
    Color? valueColor,
    bool isCode = false,
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMultiline ? 13 : 14,
                    fontWeight: isMultiline ? FontWeight.normal : FontWeight.w500,
                    color: valueColor ?? (isDarkMode ? Colors.white : Colors.black),
                    fontFamily: isCode ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== GET PERMISSIONS LIST ==========
  String _getPermissionsList(AppUser user) {
    List<String> permissions = [];
    
    if (user.canProcessSales) permissions.add('Process Sales');
    if (user.canManageInventory) permissions.add('Manage Inventory');
    if (user.canViewReports) permissions.add('View Reports');
    if (user.canManageUsers) permissions.add('Manage Users');
    
    return permissions.isEmpty ? 'No permissions' : permissions.join('\n• ');
  }

  Color _getRoleColor(String role, bool isDarkMode) {
    switch (role) {
      case 'owner':
        return isDarkMode ? Colors.green.shade400 : Colors.green;
      case 'manager':
        return isDarkMode ? Colors.blue.shade400 : Colors.blue;
      case 'worker':
        return isDarkMode ? Colors.orange.shade400 : Colors.orange;
      default:
        return isDarkMode ? Colors.grey.shade400 : Colors.grey;
    }
  }

  // ========== ADD USER DIALOG ==========
  void _showAddUserDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final _phoneController = TextEditingController();
    final _storeNameController = TextEditingController();
    String _selectedRole = 'worker';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New User',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: const OutlineInputBorder(),
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: const OutlineInputBorder(),
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    filled: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: const OutlineInputBorder(),
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    filled: true,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: const OutlineInputBorder(),
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    filled: true,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _storeNameController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Store Name *',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    border: const OutlineInputBorder(),
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    filled: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter store name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role *',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'worker',
                      child: Text('Worker'),
                    ),
                    DropdownMenuItem(
                      value: 'manager',
                      child: Text('Manager'),
                    ),
                  ],
                  onChanged: (value) {
                    _selectedRole = value!;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                try {
                  await _authService.signUp(
                    email: _emailController.text.trim(),
                    password: _passwordController.text,
                    name: _nameController.text.trim(),
                    role: _selectedRole,
                    phone: _phoneController.text.trim(),
                    storeName: _storeNameController.text.trim(),
                  );
                  
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'User added successfully!',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        backgroundColor: isDarkMode ? Colors.green.shade400 : Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: ${e.toString().replaceFirst('Exception: ', '')}',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        backgroundColor: isDarkMode ? Colors.red.shade400 : Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add User'),
          ),
        ],
      ),
    );
  }

  // ========== EDIT USER ROLE DIALOG ==========
  void _showEditUserDialog(BuildContext context, AppUser user) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final roles = ['owner', 'manager', 'worker'];
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit User Role',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'User: ${user.name}',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${user.email}',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              items: roles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                selectedRole = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _authService.updateUserRole(user.id, selectedRole);
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'User role updated successfully!',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      backgroundColor: isDarkMode ? Colors.green.shade400 : Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString().replaceFirst('Exception: ', '')}',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      backgroundColor: isDarkMode ? Colors.red.shade400 : Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // ========== TOGGLE USER ACTIVE ==========
  void _toggleUserActive(BuildContext context, AppUser user) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          user.isActive ? 'Deactivate User' : 'Activate User',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: Text(
          user.isActive
              ? 'Are you sure you want to deactivate ${user.name}?\n\n'
                'They will not be able to login.'
              : 'Are you sure you want to activate ${user.name}?\n\n'
                'They will be able to login again.',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _authService.toggleUserActive(user.id, !user.isActive);
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        user.isActive
                            ? 'User deactivated successfully!'
                            : 'User activated successfully!',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      backgroundColor: isDarkMode ? Colors.green.shade400 : Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString().replaceFirst('Exception: ', '')}',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      backgroundColor: isDarkMode ? Colors.red.shade400 : Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive
                  ? (isDarkMode ? Colors.red.shade400 : Colors.red)
                  : (isDarkMode ? Colors.green.shade400 : Colors.green),
              foregroundColor: Colors.white,
            ),
            child: Text(
              user.isActive ? 'Deactivate' : 'Activate',
            ),
          ),
        ],
      ),
    );
  }

  // ========== DELETE USER ==========
  void _deleteUser(BuildContext context, AppUser user) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete User',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: Text(
          'Are you sure you want to delete ${user.name}?\n\n'
          'This action cannot be undone.',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final currentUser = await _authService.getCurrentUserData();
                if (currentUser?.businessId != null) {
                  await FirebaseFirestore.instance
                      .collection('businesses')
                      .doc(currentUser!.businessId)
                      .collection('users')
                      .doc(user.id)
                      .delete();
                }
                
                await FirebaseFirestore.instance
                    .collection('userBusinessLookup')
                    .doc(user.id)
                    .delete();
                    
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'User deleted successfully!',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      backgroundColor: isDarkMode ? Colors.green.shade400 : Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString().replaceFirst('Exception: ', '')}',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      backgroundColor: isDarkMode ? Colors.red.shade400 : Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.red.shade400 : Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}