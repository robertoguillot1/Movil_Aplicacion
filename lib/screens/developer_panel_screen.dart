// screens/developer_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/developer_service.dart';
import '../models/user.dart';
import 'package:intl/intl.dart';

class DeveloperPanelScreen extends StatefulWidget {
  const DeveloperPanelScreen({super.key});

  @override
  State<DeveloperPanelScreen> createState() => _DeveloperPanelScreenState();
}

class _DeveloperPanelScreenState extends State<DeveloperPanelScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar usuarios después de que el widget se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final developerService = Provider.of<DeveloperService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Validar que el usuario sea desarrollador
      if (!authService.isDeveloper) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Acceso denegado. Solo desarrolladores pueden acceder.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      developerService.loadAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, DeveloperService>(
      builder: (context, authService, developerService, child) {
        // Validación de seguridad
        if (!authService.isDeveloper) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Panel del Desarrollador'),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Acceso Denegado',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Solo los desarrolladores pueden acceder a este panel.'),
                ],
              ),
            ),
          );
        }

        final stats = developerService.getStatistics();

        return Scaffold(
          appBar: AppBar(
            title: const Text('🔧 Panel del Desarrollador'),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => developerService.loadAllUsers(),
                tooltip: 'Actualizar',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle),
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog(context, authService);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'logout',
                    child: const Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Cerrar Sesión'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: developerService.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => developerService.loadAllUsers(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dashboard de Estadísticas
                        _buildStatsDashboard(stats),
                        const SizedBox(height: 24),
                        
                        // Lista de Usuarios
                        const Text(
                          '👥 Gestión de Usuarios',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Tabla de usuarios (responsive)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 600) {
                              return _buildUserListMobile(developerService.users, context);
                            } else {
                              return _buildUserTableDesktop(developerService.users, context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildStatsDashboard(Map<String, int> stats) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Estadísticas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Usuarios',
                    stats['total']!.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Activos',
                    stats['active']!.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'En Prueba',
                    stats['inTrial']!.toString(),
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Expirados',
                    stats['expired']!.toString(),
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserTableDesktop(List<UserModel> users, BuildContext context) {
    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Rol', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Suscripción', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Expiración', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Prueba', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: users.map((user) {
            return DataRow(
              cells: [
                DataCell(Text(user.fullName)),
                DataCell(Text(user.email)),
                DataCell(_buildRoleChip(user.role)),
                DataCell(
                  Icon(
                    user.hasActiveSubscription ? Icons.check_circle : Icons.cancel,
                    color: user.hasActiveSubscription ? Colors.green : Colors.red,
                  ),
                ),
                DataCell(Text(
                  user.subscriptionExpiryDate != null
                      ? DateFormat('dd/MM/yyyy').format(user.subscriptionExpiryDate!)
                      : '-',
                )),
                DataCell(Text(user.isInTrial ? '${user.trialDays} días' : '-')),
                DataCell(_buildStatusChip(user)),
                DataCell(_buildActionButtons(user, context)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUserListMobile(List<UserModel> users, BuildContext context) {
    if (users.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No hay usuarios registrados'),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(user).withOpacity(0.2),
              child: Icon(
                _getStatusIcon(user),
                color: _getStatusColor(user),
              ),
            ),
            title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user.email),
            trailing: _buildStatusChip(user),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Rol', _buildRoleChip(user.role)),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Suscripción',
                      Icon(
                        user.hasActiveSubscription ? Icons.check_circle : Icons.cancel,
                        color: user.hasActiveSubscription ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Expiración Susc.',
                      Text(
                        user.subscriptionExpiryDate != null
                            ? DateFormat('dd/MM/yyyy').format(user.subscriptionExpiryDate!)
                            : '-',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Días de Prueba', Text(user.isInTrial ? '${user.trialDays} días' : '-')),
                    const Divider(height: 24),
                    _buildActionButtons(user, context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, Widget value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        value,
      ],
    );
  }

  Widget _buildRoleChip(String role) {
    Color color;
    switch (role.toLowerCase()) {
      case 'developer':
        color = Colors.purple;
        break;
      case 'admin':
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
    }
    
    return Chip(
      label: Text(role.toUpperCase(), style: const TextStyle(fontSize: 10)),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatusChip(UserModel user) {
    Color color;
    String text;
    IconData icon;

    if (user.hasActiveSubscription) {
      color = Colors.green;
      text = 'Activo';
      icon = Icons.check_circle;
    } else if (user.isInTrial) {
      color = Colors.orange;
      text = 'Prueba';
      icon = Icons.schedule;
    } else {
      color = Colors.red;
      text = 'Expirado';
      icon = Icons.cancel;
    }

    return Chip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(text, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Color _getStatusColor(UserModel user) {
    if (user.hasActiveSubscription) return Colors.green;
    if (user.isInTrial) return Colors.orange;
    return Colors.red;
  }

  IconData _getStatusIcon(UserModel user) {
    if (user.hasActiveSubscription) return Icons.check_circle;
    if (user.isInTrial) return Icons.schedule;
    return Icons.cancel;
  }

  Widget _buildActionButtons(UserModel user, BuildContext context) {
    final developerService = Provider.of<DeveloperService>(context, listen: false);
    
    // Detectar si estamos en una vista mobile (dentro de ExpansionTile)
    final isMobileView = MediaQuery.of(context).size.width < 600;
    
    if (isMobileView) {
      // En mobile, mostrar botones en columna para evitar sobreposiciones
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Activar/Desactivar Suscripción
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _toggleSubscription(context, user, developerService),
              icon: Icon(user.hasActiveSubscription ? Icons.block : Icons.check_circle, size: 18),
              label: Text(user.hasActiveSubscription ? 'Desactivar' : 'Activar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: user.hasActiveSubscription ? Colors.orange : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Modificar Días de Prueba
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _modifyTrialDays(context, user, developerService),
              icon: const Icon(Icons.access_time, size: 18),
              label: const Text('Modificar Días de Prueba'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Cambiar Rol
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _changeUserRole(context, user, developerService),
              icon: const Icon(Icons.admin_panel_settings, size: 18),
              label: const Text('Cambiar Rol'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Resetear Contraseña
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _resetPassword(context, user, developerService),
              icon: const Icon(Icons.lock_reset, size: 18),
              label: const Text('Resetear Contraseña'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Eliminar Usuario
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _deleteUser(context, user, developerService),
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('Eliminar Usuario'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ),
        ],
      );
    } else {
      // En desktop/DataTable, usar un menú desplegable para evitar sobreposiciones
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 20),
        tooltip: 'Acciones',
        onSelected: (value) {
          switch (value) {
            case 'toggle_subscription':
              _toggleSubscription(context, user, developerService);
              break;
            case 'modify_trial':
              _modifyTrialDays(context, user, developerService);
              break;
            case 'change_role':
              _changeUserRole(context, user, developerService);
              break;
            case 'reset_password':
              _resetPassword(context, user, developerService);
              break;
            case 'delete':
              _deleteUser(context, user, developerService);
              break;
          }
        },
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            value: 'toggle_subscription',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.hasActiveSubscription ? Icons.block : Icons.check_circle,
                  color: user.hasActiveSubscription ? Colors.orange : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    user.hasActiveSubscription ? 'Desactivar Suscripción' : 'Activar Suscripción',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'modify_trial',
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text('Modificar Días de Prueba'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'change_role',
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.purple, size: 20),
                SizedBox(width: 8),
                Text('Cambiar Rol'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'reset_password',
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_reset, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('Resetear Contraseña'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text('Eliminar Usuario'),
              ],
            ),
          ),
        ],
      );
    }
  }

  void _toggleSubscription(BuildContext context, UserModel user, DeveloperService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.hasActiveSubscription ? 'Desactivar Suscripción' : 'Activar Suscripción'),
        content: Text(
          user.hasActiveSubscription
              ? '¿Estás seguro de desactivar la suscripción de ${user.fullName}?'
              : '¿Activar suscripción de 30 días para ${user.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await service.toggleSubscription(user.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.hasActiveSubscription ? Colors.orange : Colors.green,
            ),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _modifyTrialDays(BuildContext context, UserModel user, DeveloperService service) {
    final controller = TextEditingController(text: user.trialDays.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modificar Días de Prueba'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Usuario: ${user.fullName}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Días de prueba',
                border: OutlineInputBorder(),
                hintText: 'Ingresa el número de días',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final days = int.tryParse(controller.text) ?? 0;
              Navigator.pop(context);
              await service.updateTrialDays(user.id!, days);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _changeUserRole(BuildContext context, UserModel user, DeveloperService service) {
    String? selectedRole = user.role;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('🔐 Cambiar Rol de Usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Usuario: ${user.fullName}'),
              Text('Rol actual: ${_getRoleName(user.role)}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Nuevo rol',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'worker',
                    child: Text('Trabajador'),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Administrador'),
                  ),
                  DropdownMenuItem(
                    value: 'developer',
                    child: Text('Desarrollador'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRole = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                '⚠️ Solo los desarrolladores pueden cambiar roles.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedRole == null || selectedRole == user.role
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await service.changeUserRole(user.id!, selectedRole!);
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('Cambiar Rol', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'worker':
        return 'Trabajador';
      case 'admin':
        return 'Administrador';
      case 'developer':
        return 'Desarrollador';
      default:
        return role;
    }
  }

  void _resetPassword(BuildContext context, UserModel user, DeveloperService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔐 Resetear Contraseña'),
        content: Text(
          '¿Enviar email de reset de contraseña a ${user.email}?\n\n'
          'El usuario recibirá un email con instrucciones para crear una nueva contraseña.\n\n'
          '⚠️ Nota: No es posible ver la contraseña actual por seguridad.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await service.resetUserPassword(user.email);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Enviar Email', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteUser(BuildContext context, UserModel user, DeveloperService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Eliminar Usuario'),
        content: Text(
          '¿Estás seguro de eliminar permanentemente a ${user.fullName} (${user.email})?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await service.deleteUser(user.id!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

