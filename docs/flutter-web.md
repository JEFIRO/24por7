# Flutter Web

O painel Web é gerado a partir do mesmo projeto Android.

```bash
flutter run -d chrome --dart-define=API_URL=http://localhost:8080
flutter build web --release --dart-define=API_URL=https://api.exemplo.com
```

As rotas usam hash e sobrevivem a refresh sem configuração de rewrite. JWT fica
somente em memória; recarregar a aba exige autenticar novamente e retorna à rota
pretendida. Upload/download XLSX usa `file_picker`, sem `dart:html` em código
comum. OAuth Mercado Pago abre a URL fornecida pelo backend, que continua dono
do callback e dos segredos.

