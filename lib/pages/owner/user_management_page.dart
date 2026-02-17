import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/activity_log.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../core/logger.dart';
import '../../widgets/sidebar_layout.dart';
import '../kasir/kasir_riwayat.dart';

class UserManagementPage extends StatefulWidget {
  final bool isEmbedded;
  
  const UserManagementPage({
    super.key, 
    this.isEmbedded = false,
  });

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final UserService _userService = UserService();
  bool isLoading = true;
  List<User> users = [];
  String selectedTab = 'users'; // 'users' or 'activity'

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _loadData();
  }

  void _checkPermission() {
    final currentUser = AuthService().getCurrentUser();
    if (currentUser == null || currentUser.role != AppConstants.roleOwner) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses ditolak. Hanya owner yang dapat mengakses halaman ini.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final usersList = await _userService.getAllUsers();
      setState(() {
        users = usersList;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton('users', 'Users', Icons.people),
              ),
              Expanded(
                child: _buildTabButton('activity', 'Activity Log', Icons.history),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: selectedTab == 'users' ? _buildUsersTab() : _buildActivityLogTab(),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Stack(
        children: [
          content,
          if (selectedTab == 'users')
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _showAddUserDialog,
                mini: true, 
                child: const Icon(Icons.add),
              ),
            ),
        ],
      );
    }

    // Use LayoutBuilder for responsive design
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop layout with sidebar
        if (constraints.maxWidth >= 768) {
          return SidebarLayout(
            title: 'Manajemen User',
            items: [
              SidebarItem(
                label: 'Dashboard',
                icon: Icons.dashboard_rounded,
                onTap: () => Navigator.of(context)
                    .pushReplacementNamed(AppRoutes.ownerDashboard),
              ),
              SidebarItem(
                label: 'Manajemen User',
                icon: Icons.people,
                isActive: true,
                onTap: () {},
              ),
              SidebarItem(
                label: 'Riwayat Pesanan',
                icon: Icons.history,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KasirRiwayat(userRole: 'owner'),
                    ),
                  );
                },
              ),
              SidebarItem(
                label: 'Keluar',
                icon: Icons.logout,
                isDestructive: true,
                onTap: () => AppRoutes.logout(context),
              ),
            ],
            body: Stack(
              children: [
                content,
                if (selectedTab == 'users')
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: FloatingActionButton.extended(
                      onPressed: _showAddUserDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah User'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          );
        }
        
        // Mobile layout (original)
        return Scaffold(
          appBar: AppBar(
            title: const Text('Manajemen User/Staff'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          body: content,
          floatingActionButton: selectedTab == 'users'
              ? FloatingActionButton.extended(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah User'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                )
              : null,
        );
      },
    );
  }

  Widget _buildTabButton(String tab, String label, IconData icon) {
    final isSelected = selectedTab == tab;
    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = tab;
        });
        if (tab == 'activity') {
          _loadActivityLogs();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada user',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final roleColor = _getRoleColor(user.role);
    final roleIcon = _getRoleIcon(user.role);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.2),
          child: Icon(roleIcon, color: roleColor),
        ),
        title: Text(
          user.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            if (user.phone != null) Text(user.phone!),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatRole(user.role),
                style: TextStyle(
                  color: roleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'activity',
              child: Row(
                children: [
                  Icon(Icons.history, size: 18),
                  SizedBox(width: 8),
                  Text('Activity Log'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Hapus', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditUserDialog(user);
            } else if (value == 'activity') {
              _showUserActivityLog(user);
            } else if (value == 'delete') {
              _showDeleteUserDialog(user);
            }
          },
        ),
      ),
    );
  }

  Widget _buildActivityLogTab() {
    return FutureBuilder<List<ActivityLog>>(
      future: _userService.getAllActivityLogs(limit: 100),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada activity log',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return _buildActivityLogItem(log);
          },
        );
      },
    );
  }

  Widget _buildActivityLogItem(ActivityLog log) {
    return FutureBuilder<User?>(
      future: _userService.getUserById(log.userId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getActionColor(log.action).withValues(alpha: 0.2),
              child: Icon(
                _getActionIcon(log.action),
                color: _getActionColor(log.action),
                size: 20,
              ),
            ),
            title: Text(
              log.description ?? log.action,
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: ${user?.username ?? log.userId}'),
                Text('Waktu: ${_formatDateTime(log.createdAt)}'),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  void _showAddUserDialog() {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    String? selectedRole = 'kasir';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah User Baru'),
        content: StatefulBuilder(
          builder: (context, setState) => Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email harus diisi';
                      }
                      if (!value.contains('@')) {
                        return 'Email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password harus diisi';
                      }
                      if (value.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'No. Telepon',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role *',
                      prefixIcon: Icon(Icons.work),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                      DropdownMenuItem(value: 'kurir', child: Text('Kurir')),
                    ],
                    onChanged: (value) {
                      selectedRole = value;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await _userService.createUser(
                    username: usernameController.text.trim(),
                    email: emailController.text.trim(),
                    role: selectedRole!,
                    password: passwordController.text.trim(),
                    phone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User berhasil ditambahkan'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(User user) {
    final usernameController = TextEditingController(text: user.username);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    String? selectedRole = user.role;
    final formKey = GlobalKey<FormState>();
    final currentUserId = AuthService().getCurrentUser()?.id;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: StatefulBuilder(
          builder: (context, setState) => Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username *',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email harus diisi';
                      }
                      if (!value.contains('@')) {
                        return 'Email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password Baru',
                      helperText: user.id == currentUserId
                          ? 'Isi untuk ganti password akun ini'
                          : 'Akan mengirim reset password ke email',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: obscurePassword,
                    validator: (value) {
                      if (value != null && value.isNotEmpty && value.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'No. Telepon',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role *',
                      prefixIcon: Icon(Icons.work),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                      DropdownMenuItem(value: 'kurir', child: Text('Kurir')),
                      DropdownMenuItem(value: 'owner', child: Text('Owner')),
                    ],
                    onChanged: (value) {
                      selectedRole = value;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final passwordValue = passwordController.text.trim();
                  final updatedUser = User(
                    id: user.id,
                    username: usernameController.text.trim(),
                    email: emailController.text.trim(),
                    role: selectedRole!,
                    phone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                  );

                  await _userService.updateUser(updatedUser);
                  if (passwordValue.isNotEmpty) {
                    if (user.id == currentUserId) {
                      await AuthService().updatePassword(passwordValue);
                    } else {
                      await AuthService().sendPasswordReset(updatedUser.email);
                    }
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        passwordValue.isNotEmpty && user.id != currentUserId
                            ? 'User diupdate, email reset password dikirim'
                            : 'User berhasil diupdate',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus User'),
        content: Text('Apakah Anda yakin ingin menghapus user "${user.username}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _userService.deleteUser(user.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadData();
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showUserActivityLog(User user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Activity Log',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user.username,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<ActivityLog>>(
                  future: _userService.getActivityLogsByUserId(user.id, limit: 50),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final logs = snapshot.data ?? [];

                    if (logs.isEmpty) {
                      return const Center(
                        child: Text('Belum ada activity log'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return _buildActivityLogItem(log);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadActivityLogs() async {
    setState(() {});
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.purple;
      case 'kasir':
        return Colors.blue;
      case 'kurir':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'owner':
        return Icons.admin_panel_settings;
      case 'kasir':
        return Icons.point_of_sale;
      case 'kurir':
        return Icons.local_shipping;
      default:
        return Icons.person;
    }
  }

  String _formatRole(String role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'kasir':
        return 'Kasir';
      case 'kurir':
        return 'Kurir';
      default:
        return role;
    }
  }

  Color _getActionColor(String action) {
    if (action.contains('CREATE')) return Colors.green;
    if (action.contains('UPDATE')) return Colors.blue;
    if (action.contains('DELETE')) return Colors.red;
    return Colors.grey;
  }

  IconData _getActionIcon(String action) {
    if (action.contains('CREATE')) return Icons.add_circle;
    if (action.contains('UPDATE')) return Icons.edit;
    if (action.contains('DELETE')) return Icons.delete;
    return Icons.info;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}



