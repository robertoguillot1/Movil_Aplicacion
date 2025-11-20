import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';

class CustomerForm extends StatefulWidget {
  final Customer? customer;

  const CustomerForm({super.key, this.customer});

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  final _formKey = GlobalKey<FormState>();
  late String name, email, phone;

  @override
  void initState() {
    super.initState();
    name = widget.customer?.name ?? '';
    email = widget.customer?.email ?? '';
    phone = widget.customer?.phone ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<CustomerService>(context, listen: false);
    final isEdit = widget.customer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Cliente' : 'Nuevo Cliente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  hintText: 'Ej: Juan Pérez',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.trim().isEmpty ? 'El nombre es obligatorio' : null,
                onSaved: (v) => name = v!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: email,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico (Opcional)',
                  hintText: 'ejemplo@correo.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                onSaved: (v) => email = v ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (Opcional)',
                  hintText: '3001234567',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                onSaved: (v) => phone = v ?? '',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(isEdit ? 'Guardar Cambios' : 'Registrar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    if (isEdit) {
                      service.updateCustomer(Customer(
                        id: widget.customer!.id,
                        name: name,
                        email: email,
                        phone: phone,
                      ));
                    } else {
                      service.addCustomer(name, email: email, phone: phone);
                    }
                    Navigator.pop(context);
                  }
                },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
