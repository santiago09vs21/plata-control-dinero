# Plata — Control de dinero

Aplicación web instalable (PWA) para registrar entradas, salidas, dinero inicial y pagos parciales en pesos colombianos (COP). Frontend en HTML, CSS y JavaScript; persistencia en Supabase (PostgreSQL) y autenticación por correo.

## Incluye

- Dashboard: saldo disponible, dinero inicial, entradas recibidas, salidas pagadas, actividad reciente, pendientes y distribución por medio de pago.
- Entradas y salidas con descripción, valor total, fecha/hora, categoría, medio de pago y nota.
- Pagos parciales: cada abono se guarda por separado; saldo pendiente = valor total menos suma de abonos.
- Medios de pago: efectivo, transferencia, Nequi, Bancolombia, Daviplata, Bre-B y otro.
- Búsqueda y filtros; exportación del historial a CSV.
- Diseño adaptable a escritorio y celular, navegación móvil, PWA instalable y shell offline básico.
- Supabase Auth y políticas RLS para aislar los datos por usuario.

## Antes de empezar

Necesitas una cuenta en [Supabase](https://supabase.com/) y una cuenta de GitHub. No es necesario instalar Node.js: es una web estática.

## 1. Crear el proyecto y la base de datos en Supabase

1. Entra a Supabase y crea un proyecto nuevo. Guarda la contraseña de base de datos en un lugar seguro.
2. Espera a que el proyecto termine de crearse.
3. En el menú lateral abre **SQL Editor** → **New query**.
4. Abre `supabase/schema.sql` de esta carpeta, copia todo su contenido, pégalo en el editor SQL y pulsa **Run**. Debe ejecutarse sin errores.
5. En el panel del proyecto entra a **Project Settings → API** (en algunas interfaces aparece como **Connect** o **API Keys**). Copia la **Project URL** y la clave pública **Publishable** (`sb_publishable_…`) o la clave heredada `anon`.
6. Ve a **Authentication → Sign In / Providers** y confirma que Email esté habilitado. Para pruebas puedes decidir si desactivar confirmación de correo en Authentication → URL Configuration / Providers, según la interfaz vigente. Si mantienes confirmación activa, confirma el correo recibido.
7. Para que el inicio de sesión funcione publicado, en **Authentication → URL Configuration** agrega la URL pública de tu app a **Site URL** y **Redirect URLs**. Por ejemplo, `https://TU-USUARIO.github.io/TU-REPOSITORIO/`. No uses un dominio inventado: coloca el que GitHub Pages te asigne.

## 2. Conectar la aplicación

1. Abre la aplicación por medio de un servidor web local o su URL publicada (no abras `index.html` directamente con `file://`, porque el service worker/PWA y algunas funciones del navegador requieren HTTP/HTTPS).
2. La primera vez aparece **Conecta tu espacio**.
3. Pega Project URL y Publishable/anon key; pulsa **Guardar conexión**.
4. Crea una cuenta con correo y contraseña desde **Crear cuenta**. Si Supabase exige confirmación, confirma desde tu correo y vuelve a iniciar sesión.
5. Una vez dentro, crea una entrada de prueba pequeña, un gasto de prueba y un registro con abono parcial. Comprueba que el saldo y el pendiente se actualicen. Después puedes borrar los registros de prueba desde el panel de Supabase si lo deseas.

**Seguridad:** usa solamente la clave pública `publishable` o `anon` en el navegador. Nunca pongas `service_role`, una clave secreta o la contraseña de la base de datos en `app.js`, HTML, GitHub o el navegador. Las políticas RLS del SQL protegen los datos por usuario autenticado.

## 3. Publicar en GitHub Pages

1. Descomprime la carpeta `plata-control-dinero.zip`.
2. En GitHub crea un repositorio nuevo, por ejemplo `plata-control-dinero`. Si quieres que sea público para usar GitHub Pages gratis, selecciona **Public**. La clave publishable puede aparecer en el código del navegador; eso es normal, pero la seguridad depende de RLS y nunca debes publicar claves secretas.
3. Pulsa **Add file → Upload files** y sube el contenido de la carpeta del proyecto (no solo el ZIP). La raíz del repositorio debe contener `index.html`, `app.js`, `styles.css`, `manifest.webmanifest`, `sw.js` y la carpeta `supabase/`.
4. En el repositorio abre **Settings → Pages**.
5. En **Build and deployment**, elige **Deploy from a branch**, rama `main`, carpeta `/(root)` y guarda.
6. Espera a que GitHub Pages publique y abre la URL que muestra en Settings → Pages.
7. Copia esa URL en Supabase → Authentication → URL Configuration como se explica arriba.
8. Abre el enlace, introduce la URL y clave pública de Supabase, crea/inicia sesión y prueba los flujos.

Los nombres de algunos menús de GitHub/Supabase pueden cambiar ligeramente según la interfaz. Para un repositorio de proyecto, GitHub Pages normalmente usa la ruta `/nombre-repositorio/`; la app y el service worker están preparados para trabajar desde esa subruta.

## 4. Instalar en celular o escritorio

- **Android / Chrome:** abre la URL publicada y elige **Instalar aplicación** o **Añadir a pantalla de inicio** en el menú del navegador.
- **iPhone / Safari:** abre la URL, toca **Compartir** y **Añadir a pantalla de inicio**.
- **Computador:** en Chrome o Edge usa el icono de instalar de la barra de direcciones, si aparece.

La primera visita debe hacerse con conexión para descargar la aplicación y cargar Supabase. El service worker almacena archivos de interfaz para volver a abrir la app, pero registrar movimientos necesita internet y sesión activa. No se guardan movimientos offline ni se sincronizan automáticamente sin conexión.

## Lógica financiera

- **Dinero disponible = suma de todos los pagos de entradas − suma de todos los pagos de salidas.** El dinero inicial es una entrada marcada como “Dinero inicial”, por lo que se incluye en el saldo.
- **Pagado de un movimiento = suma de sus abonos.**
- **Pendiente = valor total del movimiento − suma de abonos.**
- Un movimiento parcialmente pagado no reduce/aumenta el saldo por su total comprometido, sino por el dinero que efectivamente se abonó. Así el saldo representa efectivo recibido menos efectivo desembolsado.
- La app no permite que un abono supere el saldo pendiente desde su formulario. Para un libro contable crítico sería recomendable añadir una validación transaccional del lado de la base de datos, especialmente si varios usuarios registran abonos simultáneamente.

## Estructura

```text
plata-control-dinero/
├── index.html
├── styles.css
├── app.js
├── manifest.webmanifest
├── sw.js
├── assets/
│   └── icon.svg
├── supabase/
│   └── schema.sql
└── README.md
```

## Notas / límites de esta primera versión

- La app permite crear y abonar movimientos, consultar, filtrar y exportar CSV. La edición/borrado de movimientos desde la interfaz no está habilitada; evita cambios manuales directos en tablas salvo que sepas cómo conservar el historial de abonos.
- Los datos están aislados por usuario. Si varias personas necesitan compartir un mismo fondo, habría que implementar grupos/roles compartidos en vez de compartir una sola cuenta.
- Las claves de conexión se guardan en `localStorage` del navegador. Solo deben ser claves públicas; puedes cambiar la conexión en Configuración.
- El resumen considera todos los movimientos registrados, no solo un rango de fechas.
