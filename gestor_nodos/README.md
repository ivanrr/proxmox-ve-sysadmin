# 🚀 Gestor de Nodos Proxmox (Proxmox Node Manager)

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash)
![Proxmox VE](https://img.shields.io/badge/Platform-Proxmox_VE-E57000?style=flat-square&logo=proxmox)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

Un script avanzado, interactivo y a prueba de fallos escrito en Bash para la administración, mantenimiento y limpieza de clústeres de **Proxmox VE**.

Creado por **Iván Romero**.

---

## ✨ Características Principales

- 🧠 **Evacuación Inteligente de Nodos:** Al realizar el mantenimiento de un nodo, el script calcula el destino óptimo para cada Máquina Virtual evaluando la RAM y el almacenamiento libre (`maxdisk`, `maxmem`) en el resto del clúster.
- 📥 **Recuperación Global (Bring Back):** Tras el mantenimiento, devuelve de forma masiva y automática todas las VMs evacuadas a sus nodos originales con un solo clic.
- 🧹 **Limpieza de Discos Huérfanos:** Escanea todos los *datastores* del clúster en busca de discos de máquinas que ya no existen y permite eliminarlos para recuperar espacio (protegiendo discos base y plantillas).
- 📜 **Historial Global Consolidado:** Recopila, fusiona y ordena los logs de todo el clúster en una única vista interactiva con códigos de color.
- 🛡️ **Ejecución Segura y Persistente:** Utiliza `tmux` automáticamente. Si pierdes la conexión SSH durante un mantenimiento, el script sigue trabajando de fondo y puedes recuperarlo al volver a conectar.
- 🔄 **Auto-Propagación:** Sincroniza la última versión del script en todos los nodos del clúster automáticamente.
- 🌐 **Multilingüe:** Soporte nativo para **Español** e **Inglés** (configurable desde el menú).

---

## ⚙️ Requisitos

- Un clúster funcional de Proxmox VE (versión 7.x o superior recomendada).
- Acceso `root` mediante SSH a los nodos.
- No requiere instalar nada manualmente (el propio script instala `jq` y `tmux` si detecta que faltan).

---

## 🚀 Instalación y Uso

1. Inicia sesión por SSH en cualquier nodo de tu clúster Proxmox.
2. Descarga el script directamente desde tu repositorio:

```bash
wget https://raw.githubusercontent.com/TU_USUARIO/TU_REPOSITORIO/main/gestor_nodos/gestor_nodos.sh
```
*(Asegúrate de cambiar `TU_USUARIO/TU_REPOSITORIO` por tu ruta real de GitHub).*

3. Dale permisos de ejecución:

```bash
chmod +x gestor_nodos.sh
```

4. ¡Ejecútalo!

```bash
./gestor_nodos.sh
```

El script te preguntará tu idioma preferido la primera vez que lo inicies.

---

## 📋 Estructura del Menú

1. **🚀 Mantenimiento de Nodo:** Evacúa máquinas virtuales e instala las últimas actualizaciones del sistema (`apt dist-upgrade`).
2. **📥 Volver a traer VM:** Muestra una lista de todas las máquinas desplazadas y permite retornarlas de forma individual, por nodo o todo el clúster a la vez.
3. **💾 Limpiar Almacenamiento:** Busca volúmenes huérfanos que ocupan espacio inútil en los discos locales.
4. **📜 Log Global:** Visor de eventos unificado.
5. **🔄 Propagar script por el clúster:** Copia este mismo script a todos los demás nodos.
6. **🌐 Cambiar Idioma / Change Language.**

---

## 🔒 Seguridad

- **Bloqueos Integrados:** Si intentas ejecutar el script desde dos nodos distintos a la vez, el sistema de candados (`/etc/pve/.gestor_lock`) evitará colisiones.
- **Modo de Prueba:** Ninguna acción destructiva (borrar discos, reiniciar nodos) se ejecuta sin requerir confirmación explícita previa del administrador.

---

## ✍️ Autor

Desarrollado por **Iván Romero**.

Siéntete libre de reportar *issues* o enviar *pull requests* si deseas colaborar con nuevas mejoras.