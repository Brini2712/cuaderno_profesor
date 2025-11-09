# Módulos de Perfil y Configuración

## Pantalla de Perfil (`perfil_screen.dart`)

### Características principales:

#### Visualización
- Avatar del usuario (con foto o inicial del nombre)
- Nombre completo
- Email (solo lectura)
- Tipo de usuario (Profesor/Alumno)
- Fecha de registro

#### Edición de perfil
- Botón "Editar" en la AppBar
- Modo edición permite:
  - Cambiar nombre
  - Cambiar foto de perfil (desde galería)
  - Botón "Cancelar" para descartar cambios
  - Botón "Guardar" para confirmar

#### Estadísticas personalizadas

**Para profesores:**
- Materias creadas
- Alumnos inscritos
- Evidencias asignadas

**Para alumnos:**
- Clases inscritas
- Evidencias asignadas
- Evidencias entregadas

#### Subida de foto
- Integración con `image_picker` para seleccionar desde galería
- Redimensionamiento automático (512x512, 85% calidad)
- Subida a Firebase Storage en carpeta `perfiles/{userId}.jpg`
- Actualización automática en Firestore

---

## Pantalla de Configuración (`configuracion_screen.dart`)

### Secciones implementadas:

#### 1. Notificaciones
- **Notificaciones generales**: Activar/desactivar todas las notificaciones
- **Recordatorios de evidencias**: Alertas sobre evidencias próximas a vencer
- **Recordatorios de asistencia**: Notificaciones de registro de asistencia

#### 2. Apariencia
- **Modo oscuro**: Toggle para cambiar tema (preparado para futura implementación)

#### 3. Cuenta
- **Correo electrónico**: Muestra el email (no editable con tooltip explicativo)
- **Cambiar contraseña**: 
  - Modal con formulario de 3 campos
  - Validación de coincidencia
  - Mínimo 6 caracteres

#### 4. Ayuda y soporte
- **Centro de ayuda**: Acceso a FAQ y tutoriales (placeholder)
- **Contactar soporte**: 
  - Email: soporte@cuadernoprofesor.com
  - Teléfono: +52 (123) 456-7890
- **Acerca de**: Dialog con versión 1.0.0 e información del app

#### 5. Datos y privacidad
- **Exportar mis datos**: Descarga de datos del usuario (preparado)
- **Política de privacidad**: Enlace a términos (preparado)

#### 6. Zona peligrosa
- **Cerrar sesión**: 
  - Confirmación con diálogo
  - Limpia estado del provider
  - Redirección a `/login`
- **Eliminar cuenta**:
  - Diálogo de advertencia roja
  - Requiere escribir "ELIMINAR" para confirmar
  - Placeholder para implementación real

---

## Integración en la aplicación

### Profesor (`profesor_home_screen.dart`)
- **Botón de configuración**: Icono ⚙️ en el trailing del NavigationRail
- **Menú del avatar**:
  - "Mi Perfil" → Abre `PerfilScreen`
  - "Cerrar Sesión" → Confirma y cierra sesión

### Alumno (`alumno_home_screen.dart`)
- **Menú del avatar**:
  - "Mi Perfil" → Abre `PerfilScreen`
  - "Configuración" → Abre `ConfiguracionScreen`
  - Separador
  - "Unirse a Clase" → Modal para código
  - Separador
  - "Cerrar Sesión" → Confirma y cierra sesión

---

## Método agregado al Provider

### `actualizarPerfil()` en `cuaderno_provider.dart`

```dart
Future<void> actualizarPerfil({String? nombre, String? fotoUrl})
```

#### Parámetros:
- `nombre`: Nuevo nombre del usuario (opcional)
- `fotoUrl`: Nueva URL de la foto (opcional)

#### Funcionalidad:
1. Valida que el usuario esté autenticado
2. Construye map de actualizaciones solo con valores proporcionados
3. Actualiza documento en Firestore (`usuarios/{userId}`)
4. Actualiza objeto local `_usuario` con `copyWith`
5. Notifica listeners para refrescar UI

#### Manejo de errores:
- Captura excepciones y las almacena en `_lastError`
- Re-lanza la excepción para que la UI pueda manejarla

---

## Dependencias requeridas

Ya están en `pubspec.yaml`:
- `image_picker: ^1.1.2` - Selección de fotos
- `firebase_storage: ^12.3.2` - Subida de archivos
- `provider: ^6.1.2` - Estado
- `go_router: ^14.2.7` - Navegación

---

## Navegación

Ambas pantallas usan navegación tradicional `Navigator.push()` en lugar de rutas nombradas, lo que permite:
- Transiciones suaves
- Contexto completo del provider
- Fácil retorno a la pantalla anterior

---

## Próximas mejoras sugeridas

1. **Modo oscuro**: Implementar ThemeMode con Provider
2. **Notificaciones push**: Integrar Firebase Cloud Messaging
3. **Cambio de contraseña real**: Conectar con Firebase Auth
4. **Exportar datos**: Generar PDF/CSV con información del usuario
5. **Eliminar cuenta**: Implementar lógica de borrado en Firestore + Auth
6. **Compresión de imágenes**: Usar `flutter_image_compress` antes de subir
7. **Cache de imágenes**: `cached_network_image` para avatares
8. **Validación de email**: Re-autenticación antes de operaciones sensibles

---

## Uso para el usuario final

### Ver y editar perfil:
1. Click en avatar (círculo con inicial)
2. Seleccionar "Mi Perfil"
3. Click en "Editar" (arriba derecha)
4. Modificar nombre o cambiar foto
5. "Guardar Cambios" o "Cancelar"

### Cambiar foto:
1. En modo edición del perfil
2. Click en ícono de cámara sobre el avatar
3. Seleccionar foto de galería
4. Esperar confirmación

### Ajustar configuración:
1. Click en avatar → "Configuración" (alumno)
   O click en ⚙️ en rail lateral (profesor)
2. Ajustar switches y opciones
3. Los cambios se guardan automáticamente

### Cerrar sesión:
1. Avatar → "Cerrar Sesión"
2. Confirmar en diálogo
3. Redirección automática a login
