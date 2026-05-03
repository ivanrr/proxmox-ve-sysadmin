# 🚀 Gestor de Nodos Proxmox (Proxmox Node Manager)

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash)
![Proxmox VE](https://img.shields.io/badge/Platform-Proxmox_VE-E57000?style=flat-square&logo=proxmox)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

Un script avanzado, interactivo y a prueba de fallos escrito en Bash para la administración, mantenimiento y limpieza de clústeres de **Proxmox VE**. 

Diseñado específicamente para automatizar el ciclo de vida del mantenimiento de los nodos y superar las limitaciones de la herramienta "Bulk Migrate" nativa.

Creado por **Iván Romero**.

---

## ✨ ¿Por qué usar este script frente al Bulk Migrate de Proxmox?

El *Bulk Migrate* de la interfaz web de Proxmox es útil si necesitas mover máquinas a un **único nodo de destino**, pero requiere mucho trabajo manual si quieres repartir la carga. Este script lleva la administración a otro nivel:

- 🎯 **Evacuación Multi-Destino Inteligente:** A diferencia de Proxmox (que te obliga a elegir un único destino para todo el lote), el script reparte las VMs en distintos destinos a la vez. Primero prioriza las **tareas de replicación** para garantizar migraciones ultra-rápidas, **siempre y cuando el nodo destino no supere el 90% de su RAM prometida**. Si un destino de replicación está saturado, o si la VM no tiene replicación, el script **calcula dinámicamente su destino óptimo** evaluando la RAM y el disco, y te solicita confirmación expresa antes de aplicar las alternativas.
- 📥 **Memoria de Origen (Bring Back):** Proxmox no recuerda dónde estaban las máquinas antes del *bulk migrate*. Este script guarda un registro exacto del origen y, al terminar el mantenimiento, te permite retornar todas las VMs a su nodo original con un solo clic.
- 🔄 **Flujo de Mantenimiento Selectivo y Supervisado:** Tú decides qué tareas realizar (solo migrar, solo actualizar, o ambas). El script te guiará paso a paso, exigiendo confirmaciones explícitas antes de lanzar cada fase seleccionada para garantizar tu supervisión. Si eliges actualizar, tras vaciar el nodo limpiará paquetes huérfanos y ejecutará `apt dist-upgrade` de forma segura, asistiéndote finalmente en el reinicio.
- ⚡ **Concurrencia Controlada e Inteligente:** Tú decides el ritmo. El script ofrece un modo "Smart" capaz de paralelizar migraciones automáticamente, asegurándose de que nunca haya dos transferencias compitiendo por el ancho de banda del mismo nodo a la vez, o bien puedes fijar un número manual de tu elección.
- 🧹 **Limpieza de Discos Huérfanos Interactiva:** Escanea todos los *datastores* locales en busca de volúmenes "basura" de máquinas eliminadas y te presenta un informe detallado. Tú decides y confirmas su eliminación definitiva para recuperar gigas de espacio de forma completamente segura.
- 📜 **Historial Global Unificado:** Recopila, fusiona y ordena cronológicamente los eventos de mantenimiento y migración de *todo el clúster* en una vista única estilo tabla, con **limpieza y rotación automática** de registros de más de 30 días.
- �️ **Persistencia Anti-Cortes:** Lanzado nativamente sobre `tmux`. Si pierdes la conexión SSH a mitad de una evacuación masiva de 50 VMs, el script no se cancelará; seguirá trabajando en segundo plano hasta que vuelvas a conectar.
- 🔄 **Propagación en Clúster:** Copia la versión exacta del script que estás ejecutando localmente hacia el resto de nodos. Te permite mantener todos los servidores actualizados con tu misma versión sin depender de descargas adicionales de internet.
- 🌐 **Multilingüe:** Soporte nativo para **Español** e **Inglés** (configurable desde el menú).

---

## ⚙️ Requisitos

- Un clúster funcional de Proxmox VE (versión 7.x o superior recomendada).
- Acceso `root` mediante SSH a los nodos.
- No requiere instalar nada manualmente (el propio script instala `jq` y `tmux` si detecta que faltan).

---

## 🚀 Instalación y Uso

1. Inicia sesión por SSH en cualquier nodo de tu clúster Proxmox.
2. Ubícate en el directorio de binarios locales (para poder ejecutarlo desde cualquier lugar):

```bash
cd /usr/local/sbin
```

3. Descarga el script directamente desde tu repositorio:

```bash
wget https://raw.githubusercontent.com/ivanrr/proxmox-ve-sysadmin/main/gestor_nodos/gestor_nodos.sh
```

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

1. **🚀 Mantenimiento de Nodo:** Selección de tareas (evacuación y/o actualización), cálculo de destinos, evacuación por lotes y actualización del SO con reconfirmaciones de seguridad.
2. **📥 Volver a traer VM:** Menú de retorno selectivo basándose en el historial de mantenimientos pasados.
3. **💾 Limpiar Almacenamiento:** Escáner profundo de volúmenes no registrados en la base de datos (Orphan Disks).
4. **📜 Log Global:** Visor de registro de acciones consolidadas a nivel de clúster.
5. **🔄 Propagar script por el clúster:** Envía la copia local actualizada del script a `/usr/local/sbin/` en todos los nodos.
6. **🌐 Cambiar Idioma / Change Language.**

---

## 🔒 Seguridad

- **Uso de API y Comandos Oficiales:** El script no hace "magia" por debajo ni altera bases de datos en crudo. Utiliza estrictamente las herramientas nativas de Proxmox (`qm migrate`, `pvesm free`, `pvesh`), garantizando que toda acción pase por las validaciones de seguridad del propio hipervisor.
- **Respeto de Estados (Locks):** Antes de mover o tocar cualquier máquina, el script lee su configuración. Si Proxmox la tiene bloqueada (por ejemplo, por un backup en curso), el script la respeta, omite la acción y te informa, evitando corrupciones.
- **Bloqueos de Clúster Integrados:** Si intentas ejecutar el script desde dos nodos distintos a la vez, el sistema de candados (`/etc/pve/.gestor_lock`) evitará colisiones y daños simultáneos.
- **Prevención de Desastres:** Ninguna acción destructiva (borrar discos, reiniciar nodos) se ejecuta sin requerir confirmación explícita. El script incluso detecta si hay VMs encendidas antes de permitirte enviar la orden de reinicio.

---

## ✍️ Autor

Desarrollado por **Iván Romero**.

Siéntete libre de reportar *issues* o enviar *pull requests* si deseas colaborar con nuevas mejoras.