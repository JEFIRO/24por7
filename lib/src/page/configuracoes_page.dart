import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/app_feedback.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_content.dart';
import '../../core/widgets/async_state.dart';
import '../../core/widgets/status_badge.dart';
import '../model/api_client.dart';
import '../model/empresa_branding.dart';

typedef PickedImage = ({Uint8List bytes, String name});

Future<PickedImage?> _pickImage() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: const ['png', 'jpg', 'jpeg'],
  );
  if (file == null) return null;
  return (bytes: await file.readAsBytes(), name: file.name);
}

/// Edição da identidade da Empresa (nome, logo, cores) e do perfil do admin.
class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({
    super.key,
    this.brandingRepository,
    this.perfilRepository,
    this.pickImage = _pickImage,
  });
  final BrandingRepository? brandingRepository;
  final PerfilRepository? perfilRepository;

  /// Seletor de imagem; substituível nos testes.
  final Future<PickedImage?> Function() pickImage;

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  late final BrandingRepository _branding =
      widget.brandingRepository ?? BrandingRepository();
  late final PerfilRepository _perfil =
      widget.perfilRepository ?? PerfilRepository();

  final _empresaForm = GlobalKey<FormState>();
  final _perfilForm = GlobalKey<FormState>();

  final _nomeExibicao = TextEditingController();
  final _logoUrl = TextEditingController();
  final _logoDarkUrl = TextEditingController();

  final _nome = TextEditingController();
  final _sobrenome = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();

  bool _loading = true;
  bool _loaded = false;
  String? _error;
  bool _savingEmpresa = false;
  bool _savingPerfil = false;

  /// Cores vindas do back, devolvidas sem alteração ao salvar.
  var _cores = ('', '', '');

  /// Variante do logo em envio/remoção: 'claro', 'escuro' ou null.
  String? _logoBusy;

  @override
  void initState() {
    super.initState();
    _fillPerfil();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _nomeExibicao,
      _logoUrl,
      _logoDarkUrl,
      _nome,
      _sobrenome,
      _email,
      _telefone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic>? get _user => _perfil.client.authenticatedUser;

  void _fillPerfil() {
    final user = _user;
    _nome.text = user?['nome']?.toString() ?? '';
    _sobrenome.text = user?['sobrenome']?.toString() ?? '';
    _email.text = user?['email']?.toString() ?? '';
    _telefone.text = user?['telefone']?.toString() ?? '';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _fillEmpresa(await _branding.buscar());
      if (mounted) setState(() => _loaded = true);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillEmpresa(EmpresaBranding b) {
    _nomeExibicao.text = b.nomeExibicao;
    _logoUrl.text = b.logoUrl ?? '';
    _logoDarkUrl.text = b.logoDarkUrl ?? '';
    _cores = (b.corPrincipal, b.corSecundaria, b.corDestaque);
  }

  Future<void> _saveEmpresa() async {
    if (!_empresaForm.currentState!.validate()) return;
    setState(() => _savingEmpresa = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final saved = await _branding.salvar(
        EmpresaBranding(
          nomeExibicao: _nomeExibicao.text,
          logoUrl: _logoUrl.text,
          logoDarkUrl: _logoDarkUrl.text,
          corPrincipal: _cores.$1,
          corSecundaria: _cores.$2,
          corDestaque: _cores.$3,
        ),
      );
      if (mounted) setState(() => _fillEmpresa(saved));
      messenger.showSnackBar(
        const SnackBar(content: Text('Dados da Empresa salvos')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(_message(error))));
    } finally {
      if (mounted) setState(() => _savingEmpresa = false);
    }
  }

  Future<void> _savePerfil() async {
    if (!_perfilForm.currentState!.validate()) return;
    setState(() => _savingPerfil = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _perfil.salvar(
        nome: _nome.text,
        sobrenome: _sobrenome.text,
        email: _email.text,
        telefone: _telefone.text,
      );
      if (mounted) setState(_fillPerfil);
      messenger.showSnackBar(const SnackBar(content: Text('Perfil salvo')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(_message(error))));
    } finally {
      if (mounted) setState(() => _savingPerfil = false);
    }
  }

  static String _message(Object error) =>
      error is ApiException ? error.friendlyMessage : error.toString();

  Future<void> _uploadLogo({bool escuro = false}) async {
    final messenger = ScaffoldMessenger.of(context);
    final PickedImage? picked;
    try {
      picked = await widget.pickImage();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    if (picked == null) return;
    if (picked.bytes.length > maxLogoBytes) {
      messenger.showSnackBar(
        const SnackBar(content: Text('A imagem deve ter no máximo 5 MB')),
      );
      return;
    }
    setState(() => _logoBusy = escuro ? 'escuro' : 'claro');
    try {
      final saved = await _branding.enviarLogo(
        picked.bytes,
        picked.name,
        escuro: escuro,
      );
      // Só o logo muda: edições não salvas do nome continuam no form.
      if (mounted) setState(() => _fillLogos(saved));
      messenger.showSnackBar(const SnackBar(content: Text('Logo enviado')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(_message(error))));
    } finally {
      if (mounted) setState(() => _logoBusy = null);
    }
  }

  Future<void> _removeLogo({bool escuro = false}) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _logoBusy = escuro ? 'escuro' : 'claro');
    try {
      final saved = await _branding.removerLogo(escuro: escuro);
      if (mounted) setState(() => _fillLogos(saved));
      messenger.showSnackBar(const SnackBar(content: Text('Logo removido')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(_message(error))));
    } finally {
      if (mounted) setState(() => _logoBusy = null);
    }
  }

  void _fillLogos(EmpresaBranding b) {
    _logoUrl.text = b.logoUrl ?? '';
    _logoDarkUrl.text = b.logoDarkUrl ?? '';
  }

  static String? _required(String? v, String label, int max) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return '$label é obrigatório';
    if (value.length > max) return '$label deve ter no máximo $max caracteres';
    return null;
  }

  static String? _httpsUrl(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return null;
    if (!RegExp(r'^https://\S{1,492}$').hasMatch(value)) {
      return 'Use um link que comece com https://';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      AppContent(
        maxWidth: AppLayout.formMaxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppPageHeader(
              title: 'Empresa e perfil',
              subtitle: 'Nome e logo da Empresa, e os seus dados.',
            ),
            const SizedBox(height: AppSpacing.xl),
            if (!_loaded && _loading)
              const AppLoadingState(
                label: 'Carregando dados da Empresa…',
                layout: AppSkeletonLayout.detail,
                inline: true,
              )
            else if (!_loaded)
              AppErrorState(
                title: 'Não foi possível carregar os dados da Empresa',
                message: _error ?? '',
                onRetry: _load,
              )
            else
              _empresa(context),
            const SizedBox(height: AppSpacing.section),
            _perfilSection(context),
            const SizedBox(height: AppSpacing.section),
          ],
        ),
      ),
    ],
  );

  Widget _saveButton({
    required Key key,
    required bool saving,
    required VoidCallback? onPressed,
  }) => Align(
    alignment: Alignment.centerRight,
    child: FilledButton.icon(
      key: key,
      onPressed: saving ? null : onPressed,
      icon: AppBusyIcon(busy: saving, icon: Icons.check),
      label: Text(saving ? 'Salvando…' : 'Salvar'),
    ),
  );

  Widget _empresa(BuildContext context) {
    final enabled = !_savingEmpresa;
    return Form(
      key: _empresaForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionTitle(
            'Empresa',
            subtitle: 'Aparece no topo do painel e na tela de login.',
          ),
          if (_error != null)
            AppBanner(tone: AppStatusTone.critical, message: _error!),
          const SizedBox(height: AppSpacing.md),
          _LogoPreview(url: _logoUrl, name: _nomeExibicao),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                key: const Key('branding-upload'),
                onPressed: _logoBusy != null || !enabled ? null : _uploadLogo,
                icon: AppBusyIcon(
                  busy: _logoBusy == 'claro',
                  icon: Icons.upload_outlined,
                ),
                label: Text(
                  _logoBusy == 'claro' ? 'Enviando…' : 'Enviar imagem',
                ),
              ),
              if (_logoUrl.text.trim().isNotEmpty)
                TextButton.icon(
                  key: const Key('branding-remove'),
                  onPressed: _logoBusy != null || !enabled ? null : _removeLogo,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remover logo'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            key: const Key('branding-nome'),
            controller: _nomeExibicao,
            enabled: enabled,
            maxLength: 150,
            decoration: const InputDecoration(labelText: 'Nome de exibição'),
            validator: (v) => _required(v, 'Nome de exibição', 150),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const Key('branding-logo'),
            controller: _logoUrl,
            enabled: enabled,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Link do logo',
              hintText: 'https://…/logo.png',
              helperText:
                  'Ou envie um PNG/JPEG de até 5 MB. Prefira fundo transparente.',
            ),
            validator: _httpsUrl,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _logoDarkUrl,
            enabled: enabled,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'Link do logo para fundo escuro (opcional)',
              hintText: 'https://…/logo-escuro.png',
              suffixIcon: IconButton(
                key: const Key('branding-upload-escuro'),
                tooltip: 'Enviar imagem',
                onPressed: _logoBusy != null || !enabled
                    ? null
                    : () => _uploadLogo(escuro: true),
                icon: AppBusyIcon(
                  busy: _logoBusy == 'escuro',
                  icon: Icons.upload_outlined,
                  size: 24,
                ),
              ),
            ),
            validator: _httpsUrl,
          ),
          const SizedBox(height: AppSpacing.lg),
          _saveButton(
            key: const Key('branding-save'),
            saving: _savingEmpresa,
            onPressed: _loading ? null : _saveEmpresa,
          ),
        ],
      ),
    );
  }

  Widget _perfilSection(BuildContext context) {
    final enabled = !_savingPerfil;
    final cpf = _user?['cpf']?.toString();
    return Form(
      key: _perfilForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionTitle(
            'Meu perfil',
            subtitle: 'Seu nome aparece no menu da conta e no início.',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _half(
                TextFormField(
                  key: const Key('perfil-nome'),
                  controller: _nome,
                  enabled: enabled,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) => _required(v, 'Nome', 100),
                ),
              ),
              _half(
                TextFormField(
                  key: const Key('perfil-sobrenome'),
                  controller: _sobrenome,
                  enabled: enabled,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Sobrenome'),
                  validator: (v) => (v?.trim().length ?? 0) > 100
                      ? 'Sobrenome deve ter no máximo 100 caracteres'
                      : null,
                ),
              ),
              _half(
                TextFormField(
                  controller: _email,
                  enabled: enabled,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'E-mail é obrigatório';
                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(value)) {
                      return 'E-mail inválido';
                    }
                    return null;
                  },
                ),
              ),
              _half(
                TextFormField(
                  controller: _telefone,
                  enabled: enabled,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone (opcional)',
                    hintText: '(11) 91234-5678',
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return null;
                    return RegExp(r'^[0-9()+\-\s]{10,20}$').hasMatch(value)
                        ? null
                        : 'Telefone inválido';
                  },
                ),
              ),
            ],
          ),
          if (cpf != null && cpf.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'CPF $cpf · não pode ser alterado',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _saveButton(
            key: const Key('perfil-save'),
            saving: _savingPerfil,
            onPressed: _savePerfil,
          ),
        ],
      ),
    );
  }

  Widget _half(Widget child) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      width: constraints.maxWidth >= 520
          ? (constraints.maxWidth - AppSpacing.md) / 2
          : constraints.maxWidth,
      child: child,
    ),
  );
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.url, required this.name});
  final TextEditingController url;
  final TextEditingController name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final link = url.text.trim();
    final initial = name.text.trim().isEmpty
        ? '?'
        : name.text.trim().characters.first.toUpperCase();
    final placeholder = Center(
      child: Text(
        initial,
        style: Theme.of(
          context,
        ).textTheme.headlineLarge?.copyWith(color: scheme.primary),
      ),
    );
    return Row(
      children: [
        Container(
          width: 88,
          height: 88,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: link.startsWith('https://')
              ? Image.network(
                  link,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.broken_image_outlined, color: scheme.error),
                )
              : placeholder,
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Text(
            name.text.trim().isEmpty ? 'Sem nome' : name.text.trim(),
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
