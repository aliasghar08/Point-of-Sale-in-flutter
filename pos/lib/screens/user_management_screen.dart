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
import 'package:pos/services/firebase_service.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleGuard(
      allowedRoles: ['owner', 'manager'],
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
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  bool _hasPermission = false;
  String? _errorMessage;
  String? _businessId;
  List<AppUser> _businessUsers = [];
  bool _isLoadingUsers = true;
  bool _isOwner = false;

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
      _isOwner = false;
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
      
      if (appUser != null && (appUser.role == 'owner' || appUser.role == 'manager')) {
        _businessId = appUser.businessId;
        _isOwner = appUser.role == 'owner';
        
        if (_businessId == null || _businessId!.isEmpty) {
          setState(() {
            _errorMessage = 'You are not associated with any business. Please contact support.';
            _isLoading = false;
          });
          return;
        }
        
        setState(() {
          _hasPermission = true;
          _errorMessage = null;
          _isLoading = false;
        });
        
        _loadBusinessUsers();
      } else {
        setState(() {
          _errorMessage = 'You need owner or manager permissions to access this screen. Your role: ${appUser?.role ?? 'unknown'}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
      setState(() {
        _errorMessage = 'Error checking permissions: $e';
        _isLoading = false;
      });
    }
  }

  // ========== LOAD BUSINESS USERS ==========
  Future<void> _loadBusinessUsers() async {
    if (_businessId == null) return;
    
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final users = await _firebaseService.getBusinessUsers(_businessId!);
      
      final appUsers = users.map((userData) {
        return AppUser(
          id: userData['id'] ?? '',
          email: userData['email'] ?? '',
          name: userData['name'] ?? '',
          role: userData['role'] ?? 'worker',
          phone: userData['phone'] ?? '',
          businessId: _businessId,
          createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isActive: userData['isActive'] ?? true,
        );
      }).toList();
      
      appUsers.sort((a, b) {
        final roleOrder = {'owner': 0, 'manager': 1, 'worker': 2};
        return (roleOrder[a.role] ?? 3).compareTo(roleOrder[b.role] ?? 3);
      });
      
      setState(() {
        _businessUsers = appUsers;
        _isLoadingUsers = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading business users: $e');
      setState(() {
        _isLoadingUsers = false;
      });
      _showSnackBar('Error loading users: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
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
      // ✅ ADDED: Floating Action Button so users can always be added
      floatingActionButton: (_hasPermission && !_isLoading && !_isLoadingUsers)
          ? FloatingActionButton.extended(
              onPressed: () => _showAddUserDialog(context),
              backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add),
              label: const Text('Add User'),
            )
          : null,
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
              'You need owner or manager permissions to access this screen.',
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
    if (_isLoadingUsers) {
      return Center(
        child: CircularProgressIndicator(
          color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700,
        ),
      );
    }

    if (_businessUsers.isEmpty) {
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
              'No team members found',
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), // Padding for FAB
      itemCount: _businessUsers.length,
      itemBuilder: (context, index) {
        final user = _businessUsers[index];
        return InkWell(
          onTap: () => _showUserDetailsDialog(context, user, isDarkMode),
          borderRadius: BorderRadius.circular(12),
          child: _buildUserCard(context, user, isDarkMode),
        );
      },
    );
  }

  // ========== DYNAMIC PERMISSION CHECKER ==========
  bool _canManageUser(AppUser targetUser, bool isCurrentUser) {
    if (isCurrentUser) return false; // Can't delete/edit yourself here
    if (_isOwner) return true; // Owner can manage anyone else
    if (targetUser.role == 'worker') return true; // Managers can only manage workers
    return false;
  }

  // ========== USER CARD ==========
  Widget _buildUserCard(BuildContext context, AppUser user, bool isDarkMode) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isCurrentUser = authProvider.currentUser?.id == user.id;
    final canManage = _canManageUser(user, isCurrentUser);

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
                    ],
                  ),
                ],
              ),
            ),
            // ✅ Only show menu if they have permission to manage this specific user
            if (canManage)
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
                  // Only Owner can edit roles
                  if (_isOwner)
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
                            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
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
                          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
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
                          style: TextStyle(color: isDarkMode ? Colors.red.shade400 : Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            // Lock icon if they can't manage
            if (!isCurrentUser && !canManage)
              Icon(
                Icons.lock_outline,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                size: 20,
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
                icon: Icons.calendar_today,
                label: 'Joined',
                value: DateFormat('dd MMM yyyy, hh:mm a').format(user.createdAt),
                isDarkMode: isDarkMode,
              ),
              _buildDetailItem(
                icon: Icons.person,
                label: 'Database ID',
                value: user.id.isNotEmpty ? user.id : 'Pending Auth Generation',
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
      ),
    );
  }

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
    
    // ✅ Set available roles based on current user's role
    final List<String> availableRoles = _isOwner ? ['worker', 'manager'] : ['worker'];
    String _selectedRole = availableRoles.first;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New User',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
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
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Full Name *',
                    labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    border: const OutlineInputBorder(),
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    filled: true,
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    border: const OutlineInputBorder(),
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    filled: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter email';
                    if (!value.contains('@')) return 'Please enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Temporary Password *',
                    labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    border: const OutlineInputBorder(),
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    filled: true,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter password';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    border: const OutlineInputBorder(),
                    fillColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
                    filled: true,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role *',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  items: availableRoles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role[0].toUpperCase() + role.substring(1)), // Capitalize
                    );
                  }).toList(),
                  onChanged: (value) => _selectedRole = value!,
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
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                try {
                  // ✅ Generate a valid ID so Firestore doesn't crash on document('')
                  final newUserId = FirebaseFirestore.instance.collection('users').doc().id;
                  
                  await _firebaseService.addUserToBusiness(
                    userId: newUserId,
                    email: _emailController.text.trim(),
                    name: _nameController.text.trim(),
                    role: _selectedRole,
                    phone: _phoneController.text.trim(),
                    businessId: _businessId!,
                  );
                  
                  Navigator.pop(context);
                  _showSnackBar('✅ User added successfully! They must use the temporary password to log in.', isError: false);
                  _loadBusinessUsers();
                } catch (e) {
                  _showSnackBar('Error: ${e.toString().replaceFirst('Exception: ', '')}', isError: true);
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

  // ========== EDIT USER ROLE DIALOG (Only for Owner) ==========
  void _showEditUserDialog(BuildContext context, AppUser user) {
    if (!_isOwner) {
      _showSnackBar('Only the business owner can edit user roles.', isError: true);
      return;
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final roles = ['owner', 'manager', 'worker'];
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit User Role',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User: ${user.name}',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
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
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              items: roles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                );
              }).toList(),
              onChanged: (value) => selectedRole = value!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firebaseService.updateUserRoleInBusiness(
                  businessId: _businessId!,
                  userId: user.id,
                  newRole: selectedRole,
                );
                
                Navigator.pop(context);
                _showSnackBar('✅ User role updated successfully!', isError: false);
                _loadBusinessUsers();
              } catch (e) {
                _showSnackBar('Error: ${e.toString().replaceFirst('Exception: ', '')}', isError: true);
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
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: Text(
          user.isActive
              ? 'Are you sure you want to deactivate ${user.name}?\n\nThey will not be able to login.'
              : 'Are you sure you want to activate ${user.name}?\n\nThey will be able to login again.',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firebaseService.toggleUserActiveInBusiness(
                  businessId: _businessId!,
                  userId: user.id,
                  isActive: !user.isActive,
                );
                
                Navigator.pop(context);
                _showSnackBar(
                  user.isActive 
                      ? '✅ User deactivated successfully!' 
                      : '✅ User activated successfully!',
                  isError: false,
                );
                _loadBusinessUsers();
              } catch (e) {
                _showSnackBar('Error: ${e.toString().replaceFirst('Exception: ', '')}', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive
                  ? (isDarkMode ? Colors.red.shade400 : Colors.red)
                  : (isDarkMode ? Colors.green.shade400 : Colors.green),
              foregroundColor: Colors.white,
            ),
            child: Text(user.isActive ? 'Deactivate' : 'Activate'),
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
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        content: Text(
          'Are you sure you want to delete ${user.name}?\n\nThis action cannot be undone.',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firebaseService.removeUserFromBusiness(
                  businessId: _businessId!,
                  userId: user.id,
                );
                
                Navigator.pop(context);
                _showSnackBar('✅ User deleted successfully!', isError: false);
                _loadBusinessUsers();
              } catch (e) {
                _showSnackBar('Error: ${e.toString().replaceFirst('Exception: ', '')}', isError: true);
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

  // ========== SNACKBAR ==========
  void _showSnackBar(String message, {bool isError = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: isError
            ? (isDarkMode ? Colors.red.shade400 : Colors.red.shade700)
            : (isDarkMode ? Colors.green.shade400 : Colors.green.shade700),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}