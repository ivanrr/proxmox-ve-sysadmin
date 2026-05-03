#!/bin/bash

# =================================================================
# GESTOR DE NODOS PROXMOX - SINCRONIZACIÓN TOTAL & VISIBILIDAD
# Autor: Iván Romero
# =================================================================

# 1. PERSISTENCIA DE SESIÓN TMUX
if [ -z "$TMUX" ]; then
    exec tmux new-session -A -s pve_global_manager "$0" "$@"
fi

# 2. CONFIGURACIÓN Y RUTAS COMPARTIDAS
ARCHIVO_LOG="/var/log/gestor_nodos.log"
ARCHIVO_TAREA="/etc/pve/.gestor_task_active"
DIR_CANDADO="/etc/pve/.gestor_lock"
VERSION="1.0"
NODO_LOCAL=$(hostname)
SSH_OPTS="-q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -o BatchMode=yes"

touch "$ARCHIVO_LOG" 2>/dev/null

# Limpieza automática de eventos con más de 30 días de antigüedad
if [ -f "$ARCHIVO_LOG" ]; then
    limite=$(date -d "30 days ago" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
    if [ -n "$limite" ]; then
        awk -F'|' -v limit="$limite" '{
            if (length($1) >= 19 && $1 >= limit) print $0
        }' "$ARCHIVO_LOG" > "${ARCHIVO_LOG}.tmp" && mv "${ARCHIVO_LOG}.tmp" "$ARCHIVO_LOG"
    fi
fi

instalar_dependencias() {
    for dep in jq tmux; do
        if ! command -v "$dep" &> /dev/null; then 
            echo "  ⏳ Instalando dependencia faltante ($dep)..."
            apt-get update -qq && apt-get install -y -qq jq tmux > /dev/null 2>&1
        fi
    done
}
instalar_dependencias

# 3. CONFIGURACIÓN DE IDIOMA / LANGUAGE SETUP
ARCHIVO_LANG="/etc/pve/.gestor_nodos_lang"
if [ ! -f "$ARCHIVO_LANG" ]; then
    clear
    echo "==================================================="
    echo "  Select your language / Selecciona tu idioma:"
    echo "  1) English"
    echo "  2) Español"
    echo "==================================================="
    read -p "  [1/2]: " lang_choice
    if [ "$lang_choice" == "1" ]; then
        echo "en" > "$ARCHIVO_LANG"
    else
        echo "es" > "$ARCHIVO_LANG"
    fi
fi
LANG_ID=$(cat "$ARCHIVO_LANG" 2>/dev/null || echo "es")

cargar_idioma() {
    if [ "$LANG_ID" == "en" ]; then
        L_INST_DEP="Installing missing dependency"
        L_PRESS_KEY="Press 0 (and Enter) to return to the menu..."
        L_YES_CONFIRM="Yes, confirm"
        L_NO_CANCEL="No, cancel"
        L_BACK_MENU="Return to menu"
        L_RETURNING="Returning to menu..."
        L_CANCELLED="Cancelled."
        L_COMPLETED="Completed"
        L_MIG_FAILED="Migration failed"
        L_SIMULTANEOUS="Simultaneous"
        L_GATHER_LOG="GATHERING CLUSTER LOG"
        L_QUERY_LOG="Querying log on"
        L_LOG_CONSOLIDATED="Log consolidated. Opening viewer..."
        L_DATE="DATE"
        L_NODE="NODE"
        L_STATE="STATE"
        L_DETAIL="ACTION DETAIL"
        L_GLOBAL_LOG="GLOBAL CLUSTER LOG (q to exit)"
        L_COLUMNS="COLUMNS"
        L_NAVIGATE="(Navigate: Arrows | Exit: 'q')"
        L_LEADER_MONITOR="Leader node active. Monitoring..."
        L_PENDING="Pending"
        L_BLOCKED="Blocked"
        L_MIGRATING="Migrating to"
        L_CANCELLED_MIG="Cancelled"
        L_RETRYING="Retrying"
        L_FAILED="Failed"
        L_STUCK_NODE="Stuck on node"
        L_EVAC_PROG="EVACUATION PROGRESS"
        L_PRESS_C="Press 'c': Cancel queue (ongoing migrations will finish)"
        L_RETRY_EVAC="RETRYING EVACUATION"
        L_EVAC_SUMMARY="EVACUATION SUMMARY"
        L_SEE_LOG="View migration log"
        L_MIG_ERR="ERROR: Could not migrate all planned VMs."
        L_MAINT_ABORTED="Maintenance aborted (update will not be executed)."
        L_PHASE="PHASE"
        L_UPDATE="Update"
        L_LIVE_MODE="(💡 LIVE MODE: Press Ctrl+C to pause/scroll. Shift+F to resume)"
        L_CLEAN_PKG="Cleaning orphans and installing packages on"
        L_UPG_DONE="UPDATE COMPLETED. Press Ctrl+C and then 'q' to exit and continue."
        L_WAIT_BG="Waiting for background update to finish..."
        L_UPG_PHASE_DONE="Update phase completed."
        L_OPEN_SHELL="Yes, open interactive shell"
        L_CONT_SUMMARY="No, continue to final summary"
        L_OPEN_SHELL_Q="Open shell on"
        L_CONNECTING="Connecting... (Type 'exit' when done to continue script)"
        L_UPG_NOTICE="IMPORTANT: The node"
        L_UPG_NOTICE_2="has been updated."
        L_REBOOT_Q="Do you want to REBOOT the node"
        L_REBOOT_Q_NOW="now?"
        L_WARN_CRIT="CRITICAL WARNING!"
        L_VMS_RUNNING_WARN="running VMs detected on"
        L_REBOOT_WARN="Rebooting the node now will cause a hard stop of their services."
        L_SURE_REBOOT="Are you COMPLETELY SURE to reboot"
        L_REBOOT_ISSUE="Issuing reboot command to"
        L_ORDER_SENT="Order sent."
        L_REBOOT_CANC="Reboot cancelled."
        L_PROPAGATING="PROPAGATING SCRIPT ACROSS CLUSTER"
        L_SYNCING="Synchronizing"
        L_NO_IP="Could not get IP for"
        L_SYNC_DONE="Synchronization finished."
        L_MAINT_OPT="MAINTENANCE OPTIONS"
        L_SEL_TASKS="Select tasks to execute (E.g: 12, 1, 2)"
        L_MIG_RUNNING="Migrate running VMs"
        L_DETECTED="detected"
        L_UPG_NODE="Update node (apt dist-upgrade)"
        L_TASKS_EXEC="Tasks to execute"
        L_NO_VALID_TASK="Cancelled: No valid task selected."
        L_INC_STOPPED_Q="Include stopped/paused VMs?"
        L_YES_INC_STOPPED="Yes, include"
        L_NO_ONLY_RUNNING="No, migrate only running VMs"
        L_DENIED="ACTION DENIED"
        L_NO_MASS_UPG="You cannot perform a mass update"
        L_NO_MASS_UPG_2="on the same node you are connected to."
        L_LOGIN_OTHER="Log in to another cluster node and"
        L_SELECT_THERE="select it from there."
        L_VMS_NO_REPL="VMS WITHOUT REPLICATION DETECTED"
        L_VMS_NEED_CALC="VMS NEEDING DESTINATION (No replication or target RAM >90%)"
        L_REASON="REASON"
        L_NO_REPL="No Repl."
        L_RAM_FULL="RAM Full"
        L_CALC_DEST="Calculating optimal destinations based on storage..."
        L_NAME="NAME"
        L_PROPOSAL="PROPOSAL"
        L_REMAINING="REMAINING R/D (%)"
        L_NO_RESOURCES="NO RESOURCES"
        L_MIG_DECISION="MIGRATION DECISION FOR THESE VMS"
        L_WRITE_IDS="Type IDs to migrate (e.g. 101 102)"
        L_WRITE_ALL="Type 'all' to accept all proposals"
        L_WRITE_ZERO="Type '0' to skip and not migrate them"
        L_SELECTION="Selection"
        L_MAINT_PREV="MAINTENANCE PREVIEW"
        L_VMS_TO_MIG="VMs to migrate"
        L_OMITTED="SKIPPED"
        L_UPGRADE_APT="Update (apt)"
        L_YES_DIST="YES (dist-upgrade)"
        L_CONCURRENCY="MIGRATION CONCURRENCY"
        L_CONC_SINGLE="1 global task (Safest, no bandwidth saturation)"
        L_CONC_SMART="Smart (1 task per distinct destination/source node)"
        L_CONC_MANUAL="Manual (Specify exact number of tasks)"
        L_SMART="SMART"
        L_HOW_MANY_SIM="Specify how many VMs to move at once."
        L_PROC_MAINT="Proceed with maintenance?"
        L_RECOVER_VMS="BRING BACK VM (RECOVER)"
        L_NO_PENDING="No VMs pending return to their nodes."
        L_CONT_REC="Continue recovering other VMs"
        L_NO_RECORDS="(No automatic records found after maintenance)"
        L_NODES_PENDING="Nodes with pending VMs to return:"
        L_NO_MANUAL_REPL="(No external VMs replicated to this node were found either)"
        L_MANUAL_CANDIDATES="External VMs replicated to this node available to bring:"
        L_REC_SELECTION="RECOVERY SELECTION"
        L_SEL_NODE_NAME="Type a node name (e.g. pve1) for its VMs"
        L_SEL_DEST_NAME="Type a destination node (e.g. pve1) for its VMs"
        L_SEL_IDS="Type space-separated IDs (e.g. 101 102)"
        L_SEL_ALL="Type 'all' to recover ALL to their nodes"
        L_SEL_ZERO="Type '0' to cancel and return"
        L_INVALID_SEL="Invalid selection or no ID found."
        L_VMS_STOPPED_DET="STOPPED VMS DETECTED IN BATCH"
        L_YES_REC_STOPPED="Yes, also recover stopped VMs"
        L_NO_ONLY_RUN_REC="No, bring only running ones"
        L_INC_STOPPED_REC_Q="Include stopped VMs in recovery?"
        L_YES_REC_ORPH="Yes, recover VMs without replication"
        L_NO_ONLY_REPL="No, bring only those with replication"
        L_INC_ORPH_Q="Include VMs without replication?"
        L_NO_VMS_LEFT="No VMs left to recover after filters."
        L_PREV_REC_GLOBAL="GLOBAL RECOVERY PREVIEW"
        L_VMS_TO_BRING="VMs to bring back"
        L_HOW_MANY_BRING="Specify how many VMs to bring at once."
        L_START_REC_Q="Start recovery now?"
        L_REC_PROG="GLOBAL RECOVERY PROGRESS"
        L_ALREADY_HERE="Already here"
        L_NOT_FOUND="Not found in cluster"
        L_FINAL_REC_SUM="FINAL RECOVERY SUMMARY"
        L_ALL_REC_DONE="All pending VMs recovered to their nodes."
        L_SOME_PENDING="Some VMs remain pending for later."
        L_RAM="RAM"
        L_DISK="Disks"
        L_IMPACT_TITLE="TARGET RESOURCES IMPACT"
        L_FUTURE_RAM="Future Free RAM"
        L_WARN_EXTRA_DISK="Warning: ~%sGB extra disk required on %s (Unreplicated VMs)"
        L_ERR_RAM_FULL="ERROR: Some target nodes will exceed 90% RAM usage."
        L_REDUCE_VMS="Recovery blocked for safety. Please reduce the number of VMs."
        L_ORPHAN_SEARCH="SEARCHING ORPHAN DISKS"
        L_FULL_CLUSTER="FULL CLUSTER"
        L_QUERY_DB="Querying global cluster DB..."
        L_QUERY_STORE="Querying storages on"
        L_SCAN_DS="Scanning datastore"
        L_NO_ORPHANS="No orphan disks found on scanned nodes."
        L_ORPHANS_DETECTED="ORPHAN DISKS DETECTED"
        L_FORMAT="FORMAT"
        L_SIZE="SIZE"
        L_TOTAL_RECOV="TOTAL RECOVERABLE SPACE"
        L_DEL_PERM="Do you want to PERMANENTLY DELETE these"
        L_DISKS="disks?"
        L_DEL_DISKS="Deleting disks permanently..."
        L_FREEING="Freeing"
        L_CLEAN_DONE="Cleanup completed. Freed ~"
        L_SEL_TARGET="SELECT TARGET NODE"
        L_ALL_CLUSTER="All cluster"
        L_INVALID_OPT="Invalid option."
        L_TASK_ACTIVE="ACTIVE TASK: Maintenance of"
        L_CURRENT="Current"
        L_NO_VALID_DEST="No valid destination found for any VM to migrate."
        L_MIG_SELECTION="MIGRATION SELECTION"
        L_DEST_PREV="Planned destinations for VMs on this node:"
        L_LEADER_NODE="Leader node in control:"
        L_CLUSTER_DETECTS="Cluster detects ongoing maintenance."
        L_IF_INTERRUPTED="If interrupted by error, you can force"
        L_UNLOCK="unlock to free the script."
        L_YES_FORCE="Yes, force unlock"
        L_NO_MONITOR="No, just monitor log"
        L_LOCK_CLEARED="Lock cleared safely. Loading menu..."
        L_MAIN_TITLE="PROXMOX NODE MANAGER"
        L_AUTHOR="By Iván Romero"
        L_LOCAL_NODE="Connected local node"
        L_OPT_1="Node Maintenance"
        L_OPT_2="Bring back VM"
        L_OPT_3="Clean Storage"
        L_OPT_4="Global Log"
        L_OPT_5="Propagate script across cluster"
        L_OPT_6="Change Language"
        L_OPT_0="Exit"
        L_RET_MAIN="Return to main menu"
    else
        L_INST_DEP="Instalando dependencia faltante"
        L_PRESS_KEY="Presiona 0 (y Enter) para volver al menú..."
        L_YES_CONFIRM="Sí, confirmar"
        L_NO_CANCEL="No, cancelar"
        L_BACK_MENU="Volver al menú"
        L_RETURNING="Volviendo al menú..."
        L_CANCELLED="Cancelado."
        L_COMPLETED="Completado"
        L_MIG_FAILED="Falló la migración"
        L_SIMULTANEOUS="Simultáneas"
        L_GATHER_LOG="RECOPILANDO HISTORIAL DEL CLÚSTER"
        L_QUERY_LOG="Consultando log en"
        L_LOG_CONSOLIDATED="Historial consolidado. Abriendo visor..."
        L_DATE="FECHA"
        L_NODE="NODO"
        L_STATE="ESTADO"
        L_DETAIL="DETALLE DE ACCIÓN"
        L_GLOBAL_LOG="HISTORIAL GLOBAL DEL CLÚSTER (q para salir)"
        L_COLUMNS="COLUMNAS"
        L_NAVIGATE="(Navegar: Flechas | Salir: 'q')"
        L_LEADER_MONITOR="Nodo Líder liderando. Monitorizando..."
        L_PENDING="Pendiente"
        L_BLOCKED="Bloqueada"
        L_MIGRATING="Migrando a"
        L_CANCELLED_MIG="Cancelada"
        L_RETRYING="Reintentando"
        L_FAILED="Falló"
        L_STUCK_NODE="Atrapada en nodo"
        L_EVAC_PROG="PROGRESO DE EVACUACIÓN"
        L_PRESS_C="Tecla 'c': Cancelar cola (las migraciones en curso terminarán)"
        L_RETRY_EVAC="REINTENTANDO EVACUACIÓN"
        L_EVAC_SUMMARY="RESUMEN DE EVACUACIÓN"
        L_SEE_LOG="Ver log de migraciones"
        L_MIG_ERR="ERROR: No se pudieron migrar todas las VMs planificadas."
        L_MAINT_ABORTED="Se aborta el mantenimiento (no se ejecutará la actualización)."
        L_PHASE="FASE"
        L_UPDATE="Actualización"
        L_LIVE_MODE="(💡 MODO EN VIVO: Pulsa Ctrl+C para pausar y scrollear. Pulsa Shift+F para reanudar)"
        L_CLEAN_PKG="Limpiando huérfanos e instalando paquetes en"
        L_UPG_DONE="ACTUALIZACIÓN COMPLETADA. Presiona Ctrl+C y luego la tecla q para salir y continuar."
        L_WAIT_BG="Esperando a que la actualización termine en segundo plano..."
        L_UPG_PHASE_DONE="Actualización completada."
        L_OPEN_SHELL="Sí, abrir consola interactiva"
        L_CONT_SUMMARY="No, continuar al resumen final"
        L_OPEN_SHELL_Q="¿Deseas abrir consola en"
        L_CONNECTING="Conectando... (Escribe 'exit' cuando termines para continuar con el script)"
        L_UPG_NOTICE="IMPORTANTE: El nodo"
        L_UPG_NOTICE_2="ha sido actualizado."
        L_REBOOT_Q="¿Deseas REINICIAR el nodo"
        L_REBOOT_Q_NOW="ahora?"
        L_WARN_CRIT="¡ADVERTENCIA CRÍTICA!"
        L_VMS_RUNNING_WARN="máquinas virtuales EN EJECUCIÓN en"
        L_REBOOT_WARN="Reiniciar el nodo ahora provocará un corte brusco en sus servicios."
        L_SURE_REBOOT="¿Estás COMPLETAMENTE SEGURO de reiniciar"
        L_REBOOT_ISSUE="Emitiendo orden de reinicio a"
        L_ORDER_SENT="Orden enviada."
        L_REBOOT_CANC="Reinicio cancelado."
        L_PROPAGATING="PROPAGANDO SCRIPT POR EL CLÚSTER"
        L_SYNCING="Sincronizando"
        L_NO_IP="No se pudo obtener IP para"
        L_SYNC_DONE="Sincronización terminada."
        L_MAINT_OPT="OPCIONES DE MANTENIMIENTO"
        L_SEL_TASKS="Selecciona las tareas a ejecutar (Ej: 12, 1, 2)"
        L_MIG_RUNNING="Migrar VMs encendidas"
        L_DETECTED="detectadas"
        L_UPG_NODE="Actualizar nodo (apt dist-upgrade)"
        L_TASKS_EXEC="Tareas a ejecutar"
        L_NO_VALID_TASK="Cancelado: Ninguna tarea válida seleccionada."
        L_INC_STOPPED_Q="¿Incluir VMs apagadas/pausadas?"
        L_YES_INC_STOPPED="Sí, incluir"
        L_NO_ONLY_RUNNING="No, migrar solo las encendidas"
        L_DENIED="ACCIÓN DENEGADA"
        L_NO_MASS_UPG="No puedes realizar una actualización masiva"
        L_NO_MASS_UPG_2="sobre el mismo nodo al que estás conectado."
        L_LOGIN_OTHER="Inicia sesión en otro nodo del clúster y"
        L_SELECT_THERE="selecciona"
        L_VMS_NO_REPL="VMs SIN REPLICACIÓN DETECTADAS"
        L_VMS_NEED_CALC="VMs SIN DESTINO SEGURO (Sin replicación o destino RAM >90%)"
        L_REASON="MOTIVO"
        L_NO_REPL="Sin Repl."
        L_RAM_FULL="RAM Llena"
        L_CALC_DEST="Calculando destinos óptimos según almacenamiento..."
        L_NAME="NOMBRE"
        L_PROPOSAL="PROPUESTA"
        L_REMAINING="REMANENTE R/D (%)"
        L_NO_RESOURCES="SIN RECURSOS"
        L_MIG_DECISION="DECISIÓN DE MIGRACIÓN PARA ESTAS VMs"
        L_WRITE_IDS="Escribe IDs a migrar (ej: 101 102)"
        L_WRITE_ALL="Escribe 'all' para aceptar todas las propuestas"
        L_WRITE_ZERO="Escribe '0' para omitirlas y no migrarlas"
        L_SELECTION="Selección"
        L_MAINT_PREV="PREVISIÓN DE MANTENIMIENTO"
        L_VMS_TO_MIG="Máquinas a migrar"
        L_OMITTED="OMITIDO"
        L_UPGRADE_APT="Actualización (apt)"
        L_YES_DIST="SÍ (dist-upgrade)"
        L_CONCURRENCY="CONCURRENCIA DE MIGRACIÓN"
        L_CONC_SINGLE="1 tarea global (Más seguro, sin saturación)"
        L_CONC_SMART="Inteligente (1 tarea por cada nodo destino/origen distinto)"
        L_CONC_MANUAL="Manual (Indicar número exacto de tareas)"
        L_SMART="INTELIGENTE"
        L_HOW_MANY_SIM="Indica cuántas VMs deseas mover a la vez."
        L_PROC_MAINT="¿Proceder con el mantenimiento?"
        L_RECOVER_VMS="VOLVER A TRAER VM (RECUPERACIÓN)"
        L_NO_PENDING="No hay VMs pendientes de retornar a sus nodos."
        L_CONT_REC="Continuar recuperando otras VMs"
        L_NO_RECORDS="(No se encontraron registros automáticos tras mantenimientos)"
        L_NODES_PENDING="Nodos con VMs pendientes de regresar:"
        L_NO_MANUAL_REPL="(Tampoco se encontraron VMs externas con replicación hacia este nodo)"
        L_MANUAL_CANDIDATES="VMs externas replicadas hacia este nodo disponibles para traer:"
        L_REC_SELECTION="SELECCIÓN DE RECUPERACIÓN"
        L_SEL_NODE_NAME="Escribe el nombre de un nodo (ej: pve1) para sus VMs"
        L_SEL_DEST_NAME="Escribe un nodo destino (ej: pve1) para sus VMs"
        L_SEL_IDS="Escribe IDs separados por espacio (ej: 101 102)"
        L_SEL_ALL="Escribe 'all' para recuperar TODAS a sus nodos"
        L_SEL_ZERO="Escribe '0' para cancelar y volver"
        L_INVALID_SEL="Selección no válida o ningún ID encontrado."
        L_VMS_STOPPED_DET="VMs APAGADAS DETECTADAS EN EL LOTE"
        L_YES_REC_STOPPED="Sí, recuperar también las"
        L_NO_ONLY_RUN_REC="No, traer solo las que están encendidas"
        L_INC_STOPPED_REC_Q="¿Incluir VMs apagadas en la recuperación?"
        L_YES_REC_ORPH="Sí, recuperar las"
        L_NO_ONLY_REPL="No, traer solo las que tienen replicación"
        L_INC_ORPH_Q="¿Incluir VMs sin replicación?"
        L_NO_VMS_LEFT="No quedan VMs para recuperar tras aplicar los filtros."
        L_PREV_REC_GLOBAL="PREVISIÓN DE RECUPERACIÓN GLOBAL"
        L_VMS_TO_BRING="Máquinas a traer de vuelta"
        L_HOW_MANY_BRING="Indica cuántas VMs deseas traer a la vez."
        L_START_REC_Q="¿Iniciar recuperación ahora?"
        L_REC_PROG="PROGRESO DE RECUPERACIÓN GLOBAL"
        L_ALREADY_HERE="Ya estaba aquí"
        L_NOT_FOUND="No encontrada en clúster"
        L_FINAL_REC_SUM="RESUMEN FINAL DE RECUPERACIÓN"
        L_ALL_REC_DONE="Todas las VMs pendientes han sido recuperadas a sus respectivos nodos."
        L_SOME_PENDING="Algunas VMs quedaron pendientes y seguirán registradas para más adelante."
        L_RAM="RAM"
        L_DISK="Discos"
        L_IMPACT_TITLE="IMPACTO EN RECURSOS DE DESTINO"
        L_FUTURE_RAM="RAM Libre Prevista"
        L_WARN_EXTRA_DISK="Atención: Se requerirán ~%sGB extra en %s (VMs sin replicación)"
        L_ERR_RAM_FULL="ERROR: Algunos destinos superarán el 90% de uso de RAM."
        L_REDUCE_VMS="Recuperación bloqueada por seguridad. Reduce la cantidad de VMs."
        L_ORPHAN_SEARCH="BUSCANDO DISCOS HUÉRFANOS"
        L_FULL_CLUSTER="CLÚSTER COMPLETO"
        L_QUERY_DB="Consultando base de datos global del clúster..."
        L_QUERY_STORE="Consultando almacenamientos en"
        L_SCAN_DS="Escaneando datastore"
        L_NO_ORPHANS="No se han encontrado discos huérfanos en los nodos escaneados."
        L_ORPHANS_DETECTED="DISCOS HUÉRFANOS DETECTADOS"
        L_FORMAT="FORMATO"
        L_SIZE="TAMAÑO"
        L_TOTAL_RECOV="TOTAL ESPACIO RECUPERABLE"
        L_DEL_PERM="¿Deseas ELIMINAR PERMANENTEMENTE estos"
        L_DISKS="discos?"
        L_DEL_DISKS="Borrando discos permanentemente..."
        L_FREEING="Liberando"
        L_CLEAN_DONE="Limpieza completada. Se han liberado ~"
        L_SEL_TARGET="SELECCIONA EL NODO OBJETIVO"
        L_ALL_CLUSTER="Todo el clúster"
        L_INVALID_OPT="Opción no válida."
        L_TASK_ACTIVE="TAREA ACTIVA: Mantenimiento de"
        L_CURRENT="Actual"
        L_NO_VALID_DEST="No hay VMs con un destino válido para migrar."
        L_MIG_SELECTION="SELECCIÓN DE MIGRACIÓN"
        L_DEST_PREV="Destinos previstos para las VMs en este nodo:"
        L_LEADER_NODE="Nodo Líder en control:"
        L_CLUSTER_DETECTS="El clúster detecta que hay un mantenimiento en curso."
        L_IF_INTERRUPTED="Si la tarea se interrumpió por error, puedes forzar"
        L_UNLOCK="el desbloqueo para liberar el script."
        L_YES_FORCE="Sí, forzar desbloqueo"
        L_NO_MONITOR="No, solo monitorizar el log"
        L_LOCK_CLEARED="Bloqueo eliminado limpiamente. Cargando menú..."
        L_MAIN_TITLE="GESTOR DE NODOS PROXMOX"
        L_AUTHOR="By Iván Romero"
        L_LOCAL_NODE="Nodo local conectado"
        L_OPT_1="Mantenimiento de Nodo"
        L_OPT_2="Volver a traer VM"
        L_OPT_3="Limpiar Almacenamiento"
        L_OPT_4="Log Global"
        L_OPT_5="Propagar script por el clúster"
        L_OPT_6="Cambiar Idioma"
        L_OPT_0="Salir"
        L_RET_MAIN="Volver al menú principal"
    fi
}
cargar_idioma

# =================================================================
# 3. FUNCIONES AUXILIARES (REUTILIZACIÓN)
# =================================================================

obtener_ip_nodo() {
    pvesh get /nodes/$1/network --output-format json 2>/dev/null | jq -r '.[] | select(.address != null) | .address' | head -n 1
}

obtener_lista_nodos() {
    if [ "$1" == "--excluir-local" ]; then
        pvesh get /nodes --output-format json 2>/dev/null | jq -r '.[] | select(.node != "'"$NODO_LOCAL"'") | .node' | sort -u
    else
        pvesh get /nodes --output-format json 2>/dev/null | jq -r '.[].node' | sort -u
    fi
}

obtener_nodo_alternativo() {
    pvesh get /nodes --output-format json 2>/dev/null | jq -r '.[] | select(.status == "online" and .node != "'"$1"'") | .node' | head -n 1
}

pausa_volver() {
    read -p "  $L_PRESS_KEY " key
}

pedir_confirmacion() {
    echo "  s) ✅ $L_YES_CONFIRM"
    echo "  n) ❌ $L_NO_CANCEL"
    echo "---------------------------------------------------"
    echo "  0) ↩️  $L_BACK_MENU"
    echo "---------------------------------------------------"
    read -p "  $1 [s/n/0]: " confirmar
    if [[ "$confirmar" == "0" ]]; then
        echo "  $L_RETURNING"; sleep 1; return 1
    elif [[ ! "$confirmar" =~ ^[sS] ]]; then
        echo "  $L_CANCELLED"; sleep 1; return 1
    fi
    return 0
}

chequear_hilos_migracion() {
    local id res
    for id in "${!vm_pid[@]}"; do
        if ! kill -0 "${vm_pid[$id]}" 2>/dev/null; then
            wait "${vm_pid[$id]}" 2>/dev/null
            if [ -f "/tmp/.mig_status_$id" ]; then
                res=$(cat "/tmp/.mig_status_$id")
                if [ "$res" == "OK" ]; then
                    vm_status[$id]="✅ $L_COMPLETED"
                else
                    vm_status[$id]="❌ $L_MIG_FAILED"
                fi
                rm -f "/tmp/.mig_status_$id" "/tmp/.mig_latest_$id"
            fi
            unset vm_pid[$id]
            if [ -n "${vm_target_node[$id]}" ]; then
                unset active_targets["${vm_target_node[$id]}"]
            fi
            ((jobs_running--))
            ((vms_done++))
        fi
    done
}

dibujar_dashboard_migracion() {
    local titulo="$1"; local sim="$2"; shift 2; local ids=("$@")
    local id log_line
    printf "\e[1;1H"
    echo -e "=========================================================================================\e[K"
    echo -e "      $titulo ($L_SIMULTANEOUS: $sim)\e[K"
    echo -e "=========================================================================================\e[K"
    for id in "${ids[@]}"; do
        printf "  VM %-5s %-18s : %s\e[K\n" "$id" "[${vm_names[$id]:0:16}]" "${vm_status[$id]}"
        if [[ "${vm_status[$id]}" == *"$L_MIGRATING"* || "${vm_status[$id]}" == *"$L_RETRYING"* ]] && [ -f "/tmp/.mig_latest_$id" ]; then
            log_line=$(cat "/tmp/.mig_latest_$id" | tail -n 1 | tr -d '\r\n' | cut -c1-110)
            printf "      \e[90m└─ %s\e[0m\e[K\n" "$log_line"
        fi
    done
    echo -e "=========================================================================================\e[K"
    echo -e "\e[J\c"
}

# =================================================================
# 4. SISTEMA DE LOGS TIPO EXCEL
# =================================================================

registrar_log() {
    local status=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S')|$NODO_LOCAL|$status|$message" >> "$ARCHIVO_LOG"
}

mostrar_historial_cluster() {
    clear
    echo "==================================================="
    echo "      📜 $L_GATHER_LOG"
    echo "==================================================="
    
    local temp_cluster_log=$(mktemp)
    local formatted_log=$(mktemp)
    # Detección ultra-robusta de todos los nodos registrados
    local nodos=$(obtener_lista_nodos)
    local total=$(echo "$nodos" | wc -w)
    local i=0
    
    for n in $nodos; do
        ((i++))
        printf "\r  ⏳ [%-2d/%-2d] $L_QUERY_LOG: \e[36m%-15s\e[0m" "$i" "$total" "$n"
        local ip=$(obtener_ip_nodo "$n")
        if [ -n "$ip" ]; then
            ssh $SSH_OPTS root@$ip "cat $ARCHIVO_LOG 2>/dev/null" >> "$temp_cluster_log" 2>/dev/null
        fi
    done

    echo -e "\r  ✅ $L_LOG_CONSOLIDATED            \n"
    
    echo "===============================================================================" > "$formatted_log"
    echo "      📜 $L_GLOBAL_LOG" >> "$formatted_log"
    echo "===============================================================================" >> "$formatted_log"
    printf " \e[1m%-19s | %-10s | %-7s | %-40s\e[0m\n" "$L_DATE" "$L_NODE" "$L_STATE" "$L_DETAIL" >> "$formatted_log"
    echo "-------------------------------------------------------------------------------" >> "$formatted_log"
    
    # Quitamos el límite 'tail' para ver todo y lo volcamos al archivo de diseño temporal
    sort "$temp_cluster_log" | while IFS='|' read -r fecha nodo estado mensaje; do
        local color="\e[0m"
        case "$estado" in
            "OK"|"DONE") color="\e[32m" ;;
            "FAIL"|"ERR") color="\e[31m" ;;
            "INFO"|"SYS") color="\e[34m" ;;
            "REBOOT"|"MIGRATE") color="\e[33m" ;;
        esac
        printf " %-19s | %-10s | ${color}%-7s\e[0m | %-40s\n" "$fecha" "$nodo" "$estado" "$mensaje" >> "$formatted_log"
    done
    
    # Abrimos con less. -R (colores), -S (no corta líneas), -P (Fija los títulos en barra inferior)
    less -R -S -P " $L_COLUMNS: $L_DATE | $L_NODE | $L_STATE | $L_DETAIL  $L_NAVIGATE " "$formatted_log"
    
    rm -f "$temp_cluster_log" "$formatted_log"
}

# =================================================================
# 5. MOTOR DE EJECUCIÓN HA
# =================================================================

ejecutar_mantenimiento() {
    local objetivo=$1; local plan=$2; local simultaneas=$3; local mode_concurrency=$4; shift 4; local vms=("$@")
    
    local sim_display="$simultaneas"
    if [[ "$mode_concurrency" == "2" ]]; then sim_display="$L_SMART"; fi
    
    local ip_objetivo=$(obtener_ip_nodo "$objetivo")
    if [ -z "$ip_objetivo" ]; then
        echo -e "\n  ❌ ERROR: No se pudo obtener la IP del nodo $objetivo."
        pausa_volver
        return
    fi

    # Limpieza de bloqueos fantasma. Si el script llega a esta función, 
    # es porque el usuario dio la orden explícita de iniciar o reanudar.
    rm -rf "$DIR_CANDADO" 2>/dev/null

    if mkdir "$DIR_CANDADO" 2>/dev/null; then
        echo "$NODO_LOCAL" > "$DIR_CANDADO/leader"
        echo "{\"target\":\"$objetivo\",\"plan\":\"$plan\",\"status\":\"running\",\"leader\":\"$NODO_LOCAL\"}" > "$ARCHIVO_TAREA"
    else
        sleep 1 # Da tiempo al líder a escribir el archivo de tarea
        local leader=$(cat "$DIR_CANDADO/leader" 2>/dev/null)
        echo "  ⚠️  $L_LEADER_MONITOR"
        tail -n 5 -f "$ARCHIVO_LOG" &
        wait
        return
    fi

    registrar_log "INFO" "INICIO MANTENIMIENTO: $objetivo"
    local fase=1

    # FASE: MIGRACIÓN
    if [[ "$plan" == *1* ]] && [ ${#vms[@]} -gt 0 ]; then
        declare -A vm_status
        declare -A vm_names
        local res_json=$(pvesh get /cluster/resources --output-format json 2>/dev/null)
        for id in "${vms[@]}"; do
            vm_status[$id]="⏳ $L_PENDING"
            local n=$(echo "$res_json" | jq -r ".[] | select(.id == \"qemu/$id\") | .name" 2>/dev/null)
            vm_names[$id]=${n:-"?"}
        done
        local mig_log=$(mktemp)
        > "$mig_log"
        local jobs_running=0
        local vms_done=0
        local -a pending_vms=("${vms[@]}")
        local -A vm_pid
        local -A active_targets=()
        local -A vm_target_node=()

        printf "\e[2J\e[H" # Limpiar pantalla completa y reubicar cursor

        while [ $vms_done -lt ${#vms[@]} ]; do
            # 1. Lanzar nuevos trabajos si hay hueco en la concurrencia
            while [ $jobs_running -lt $simultaneas ] && [ ${#pending_vms[@]} -gt 0 ]; do
                local target_found=false
                local selected_idx=0
                local vmid=""
                local target=""
                
                for i in "${!pending_vms[@]}"; do
                    vmid="${pending_vms[$i]}"
                    target=$(grep "^$vmid:" "/etc/pve/.gestor_targets_$objetivo" 2>/dev/null | cut -d':' -f2)
                    if [ -z "$target" ]; then
                        target=$(pvesh get /cluster/replication --output-format json 2>/dev/null | jq -r ".[] | select((.guest | tostring) == \"$vmid\") | .target" 2>/dev/null | head -n 1)
                        if [ -z "$target" ]; then target=$(obtener_nodo_alternativo "$objetivo"); fi
                    fi
                    
                    if [[ "$mode_concurrency" == "2" ]]; then
                        if [ -z "${active_targets[$target]}" ]; then
                            target_found=true
                            selected_idx=$i
                            break
                        fi
                    else
                        target_found=true
                        selected_idx=$i
                        break
                    fi
                done
                
                if ! $target_found; then
                    break # No se pueden programar más simultáneas sin solaparse
                fi
                
                vmid="${pending_vms[$selected_idx]}"
                pending_vms=("${pending_vms[@]:0:$selected_idx}" "${pending_vms[@]:$((selected_idx + 1))}")
                vm_target_node[$vmid]=$target
                active_targets[$target]=1
                
                # SEGURIDAD: Comprobar bloqueo antes de intentar moverla
                local is_locked=$(pvesh get /nodes/$objetivo/qemu/$vmid/config --output-format json 2>/dev/null | jq -r '.lock // empty')
                if [ -n "$is_locked" ]; then
                    vm_status[$vmid]="⚠️  $L_BLOCKED ($is_locked)"
                    registrar_log "WARN" "Migración de VM $vmid omitida por bloqueo ($is_locked)"
                    unset active_targets[$target]
                    ((vms_done++))
                    continue
                fi

                local target=$(grep "^$vmid:" "/etc/pve/.gestor_targets_$objetivo" 2>/dev/null | cut -d':' -f2)
                if [ -z "$target" ]; then
                    target=$(pvesh get /cluster/replication --output-format json 2>/dev/null | jq -r ".[] | select((.guest | tostring) == \"$vmid\") | .target" 2>/dev/null | head -n 1)
                    if [ -z "$target" ]; then target=$(obtener_nodo_alternativo "$objetivo"); fi
                fi

                vm_status[$vmid]="🚀 $L_MIGRATING $target..."
                registrar_log "MIGRATE" "VM $vmid a $target"
                echo -e "\n=== MIGRACIÓN VM $vmid (hacia $target) ===" >> "$mig_log"

                (
                    local vm_status_real=$(pvesh get /cluster/resources --output-format json 2>/dev/null | jq -r ".[] | select(.id == \"qemu/$vmid\") | .status" 2>/dev/null)
                    local mig_cmd="qm migrate $vmid $target --with-local-disks"
                    if [ "$vm_status_real" == "running" ]; then
                        mig_cmd="qm migrate $vmid $target --online --with-local-disks"
                    fi
                    # Pipe interactivo que prefija la línea con el VMID
                    ssh $SSH_OPTS root@$ip_objetivo "$mig_cmd" 2>&1 | stdbuf -o0 tr '\r' '\n' | while IFS= read -r line; do
                        [ -z "$line" ] && continue
                        echo "$line" > "/tmp/.mig_latest_$vmid"
                        printf "[VM %s] %s\n" "$vmid" "$line" >> "$mig_log"
                    done
                    
                    local check_node=$(pvesh get /cluster/resources --output-format json 2>/dev/null | jq -r ".[] | select(.id == \"qemu/$vmid\") | .node" 2>/dev/null)
                    if [ "$check_node" == "$target" ]; then
                        echo "OK" > "/tmp/.mig_status_$vmid"
                    else
                        echo "FAIL" > "/tmp/.mig_status_$vmid"
                    fi
                ) &
                vm_pid[$vmid]=$!
                ((jobs_running++))
            done

            chequear_hilos_migracion
            dibujar_dashboard_migracion "🚀 $L_EVAC_PROG: $objetivo" "$sim_display" "${vms[@]}"
            echo -e "  [ $L_PRESS_C ]\e[K"
            echo -e "-----------------------------------------------------------------------------------------\e[K"
            echo -e "\e[J\c" # Limpia restos si la terminal se redimensiona
            local key=""
            read -t 1 -n 1 -s key
            if [[ "${key,,}" == "c" ]] && [ ${#pending_vms[@]} -gt 0 ]; then
                for cid in "${pending_vms[@]}"; do
                    vm_status[$cid]="🛑 $L_CANCELLED_MIG"
                    ((vms_done++))
                done
                pending_vms=()
            fi
        done
        
        # REINTENTO DE FALLOS
        local reintentos=()
        for id in "${vms[@]}"; do
            if [[ "${vm_status[$id]}" != "✅ $L_COMPLETED" && "${vm_status[$id]}" != "🛑 $L_CANCELLED_MIG" ]]; then
                reintentos+=("$id")
            fi
        done

        if [ ${#reintentos[@]} -gt 0 ]; then
            vms_done=0; jobs_running=0; pending_vms=("${reintentos[@]}"); vm_pid=()
            active_targets=(); vm_target_node=()
            
            printf "\e[2J\e[H"

            while [ $vms_done -lt ${#reintentos[@]} ]; do
                while [ $jobs_running -lt $simultaneas ] && [ ${#pending_vms[@]} -gt 0 ]; do
                    local target_found=false
                    local selected_idx=0
                    local vmid=""
                    local target=""
                    
                    for i in "${!pending_vms[@]}"; do
                        vmid="${pending_vms[$i]}"
                        target=$(grep "^$vmid:" "/etc/pve/.gestor_targets_$objetivo" 2>/dev/null | cut -d':' -f2)
                        if [ -z "$target" ]; then
                            target=$(pvesh get /cluster/replication --output-format json 2>/dev/null | jq -r ".[] | select((.guest | tostring) == \"$vmid\") | .target" 2>/dev/null | head -n 1)
                            if [ -z "$target" ]; then target=$(obtener_nodo_alternativo "$objetivo"); fi
                        fi
                        
                        if [[ "$mode_concurrency" == "2" ]]; then
                            if [ -z "${active_targets[$target]}" ]; then
                                target_found=true
                                selected_idx=$i
                                break
                            fi
                        else
                            target_found=true
                            selected_idx=$i
                            break
                        fi
                    done
                    
                    if ! $target_found; then
                        break
                    fi
                    
                    vmid="${pending_vms[$selected_idx]}"
                    pending_vms=("${pending_vms[@]:0:$selected_idx}" "${pending_vms[@]:$((selected_idx + 1))}")
                    vm_target_node[$vmid]=$target
                    active_targets[$target]=1
                    
                    # SEGURIDAD: Comprobar bloqueo en el reintento
                    local is_locked=$(pvesh get /nodes/$objetivo/qemu/$vmid/config --output-format json 2>/dev/null | jq -r '.lock // empty')
                    if [ -n "$is_locked" ]; then
                        vm_status[$vmid]="⚠️  $L_BLOCKED ($is_locked)"
                        registrar_log "WARN" "REINTENTO: VM $vmid sigue bloqueada ($is_locked)"
                        unset active_targets[$target]
                        ((vms_done++))
                        continue
                    fi

                    local target=$(grep "^$vmid:" "/etc/pve/.gestor_targets_$objetivo" 2>/dev/null | cut -d':' -f2)
                    if [ -z "$target" ]; then
                        target=$(pvesh get /cluster/replication --output-format json 2>/dev/null | jq -r ".[] | select((.guest | tostring) == \"$vmid\") | .target" 2>/dev/null | head -n 1)
                        if [ -z "$target" ]; then target=$(obtener_nodo_alternativo "$objetivo"); fi
                    fi

                    vm_status[$vmid]="🔄 $L_RETRYING ($target)..."
                    registrar_log "MIGRATE" "REINTENTO VM $vmid a $target"
                    echo -e "\n=== REINTENTO MIGRACIÓN VM $vmid (hacia $target) ===" >> "$mig_log"

                    (
                        local vm_status_real=$(pvesh get /cluster/resources --output-format json 2>/dev/null | jq -r ".[] | select(.id == \"qemu/$vmid\") | .status" 2>/dev/null)
                        local mig_cmd="qm migrate $vmid $target --with-local-disks"
                        if [ "$vm_status_real" == "running" ]; then
                            mig_cmd="qm migrate $vmid $target --online --with-local-disks"
                        fi
                        ssh $SSH_OPTS root@$ip_objetivo "$mig_cmd" 2>&1 | while IFS= read -r line; do
                            echo "$line" > "/tmp/.mig_latest_$vmid"
                            printf "[VM %s] %s\n" "$vmid" "$line" >> "$mig_log"
                        done
                        
                        local check_node=$(pvesh get /cluster/resources --output-format json 2>/dev/null | jq -r ".[] | select(.id == \"qemu/$vmid\") | .node" 2>/dev/null)
                        if [ "$check_node" == "$target" ]; then
                            echo "OK" > "/tmp/.mig_status_$vmid"
                        else
                            echo "FAIL" > "/tmp/.mig_status_$vmid"
                        fi
                    ) &
                    vm_pid[$vmid]=$!
                    ((jobs_running++))
                done

                for id in "${!vm_pid[@]}"; do
                    if ! kill -0 "${vm_pid[$id]}" 2>/dev/null; then
                        wait "${vm_pid[$id]}" 2>/dev/null
                        if [ -f "/tmp/.mig_status_$id" ]; then
                            local res=$(cat "/tmp/.mig_status_$id")
                            if [ "$res" == "OK" ]; then
                                vm_status[$id]="✅ $L_COMPLETED"
                            else
                                vm_status[$id]="❌ $L_FAILED"
                            fi
                            rm -f "/tmp/.mig_status_$id"
                            rm -f "/tmp/.mig_latest_$id"
                        fi
                        unset vm_pid[$id]
                        ((jobs_running--))
                        ((vms_done++))
                    fi
                done

                printf "\e[1;1H"
                echo -e "=========================================================================================\e[K"
                echo -e "      ⚠️  $L_RETRY_EVAC: $objetivo ($L_SIMULTANEOUS: $sim_display)\e[K"
                echo -e "=========================================================================================\e[K"
                for id in "${vms[@]}"; do
                    local extra=""
                    if [[ "${vm_status[$id]}" == *"$L_RETRYING"* ]] && [ -f "/tmp/.mig_latest_$id" ]; then
                        extra=" | \e[90m$(cat "/tmp/.mig_latest_$id" | tail -n 1 | cut -c1-65 | tr -d '\r\n')\e[0m"
                    fi
                    printf "  VM %-5s %-18s : %s%b\e[K\n" "$id" "[${vm_names[$id]:0:16}]" "${vm_status[$id]}" "$extra"
                done
                echo -e "=========================================================================================\e[K"
                echo -e "  [ $L_PRESS_C ]\e[K"
                echo -e "-----------------------------------------------------------------------------------------\e[K"
                echo -e "\e[J\c"
                local key=""
                read -t 1 -n 1 -s key
                if [[ "${key,,}" == "c" ]] && [ ${#pending_vms[@]} -gt 0 ]; then
                    for cid in "${pending_vms[@]}"; do
                        vm_status[$cid]="🛑 $L_CANCELLED_MIG"
                        ((vms_done++))
                    done
                    pending_vms=()
                fi
            done
        fi

        # VERIFICACIÓN ESTRICTA FEHACIENTE
        local migraciones_ok=true
        for id in "${vms[@]}"; do
            local current_node=$(pvesh get /cluster/resources --output-format json 2>/dev/null | jq -r ".[] | select(.id == \"qemu/$id\") | .node" 2>/dev/null)
            if [ "$current_node" == "$objetivo" ]; then
                migraciones_ok=false
                if [[ "${vm_status[$id]}" != "🛑 $L_CANCELLED_MIG" ]]; then
                    vm_status[$id]="❌ $L_STUCK_NODE"
                fi
            elif [[ "${vm_status[$id]}" != "✅ $L_COMPLETED" ]]; then
                if [ -n "$current_node" ] && [ "$current_node" != "$objetivo" ]; then
                    vm_status[$id]="✅ $L_COMPLETED"
                else
                    migraciones_ok=false
                fi
            fi
        done

        # RESUMEN FINAL EVACUACIÓN
        clear
        echo "==================================================="
        echo "      🏁 $L_EVAC_SUMMARY: $objetivo"
        echo "==================================================="
        for id in "${vms[@]}"; do
            printf "  VM %-5s %-18s : %s\n" "$id" "[${vm_names[$id]:0:16}]" "${vm_status[$id]}"
        done
        echo "==================================================="
        while true; do
            echo "---------------------------------------------------"
            echo "  L) 📜 $L_SEE_LOG"
            echo "  0) ↩️  $L_ABORT_MAINT"
            echo "  Enter) ⏭️  $L_CONT_MAINT"
            echo "---------------------------------------------------"
            read -p "  Selección [L/0/Enter]: " ans_log
            if [[ "${ans_log,,}" == "l" ]]; then
                less -R -P " LOG DE MIGRACIONES (Navegar: Flechas | Salir: 'q') " "$mig_log"
            elif [[ "$ans_log" == "0" ]]; then
                rm -f "$mig_log"
                rm -rf "$DIR_CANDADO" ; rm -f "$ARCHIVO_TAREA" "/etc/pve/.gestor_targets_$objetivo"
                return
            else
                break
            fi
        done
        rm -f "$mig_log"

        if ! $migraciones_ok; then
            echo -e "\n  ❌ $L_MIG_ERR"
            echo "  $L_MAINT_ABORTED"
            registrar_log "FAIL" "Mantenimiento abortado por fallo en migración de VM"
            rm -rf "$DIR_CANDADO" ; rm -f "$ARCHIVO_TAREA" "/etc/pve/.gestor_targets_$objetivo"
            pausa_volver
            return
        fi

        ((fase++))
    fi

    # FASE: ACTUALIZACIÓN
    if [[ "$plan" == *2* ]]; then
        if [ ${#vms[@]} -gt 0 ]; then
            clear
            echo "========================================================================================="
            echo "      🏁 $L_EVAC_SUMMARY: $objetivo"
            echo "========================================================================================="
            for id in "${vms[@]}"; do
                printf "  VM %-5s %-18s : %s\n" "$id" "[${vm_names[$id]:0:16}]" "${vm_status[$id]}"
            done
            echo "========================================================================================="
        fi

        registrar_log "SYS" "Ejecutando apt autoremove y dist-upgrade"
        # NOTA: En Proxmox es OBLIGATORIO usar dist-upgrade (o full-upgrade). 
        # Usar un 'upgrade' normal retiene los nuevos kernels (pve-kernel) y puede romper el nodo.
        
        local upg_log=$(mktemp)
        {
            if [ ${#vms[@]} -gt 0 ]; then
                echo "========================================================================================="
                echo "      🏁 $L_EVAC_SUMMARY: $objetivo"
                echo "========================================================================================="
                for id in "${vms[@]}"; do
                    printf "  VM %-5s %-18s : %s\n" "$id" "[${vm_names[$id]:0:16}]" "${vm_status[$id]}"
                done
                echo "========================================================================================="
                echo ""
            fi
            echo "  📦 $L_PHASE $fase: $L_UPDATE"
            echo "  $L_LIVE_MODE"
            echo "-----------------------------------------------------------------------------------------"
            printf "  ⏳ $L_CLEAN_PKG %s...\n" "$objetivo"
            echo "-----------------------------------------------------------------------------------------"
        } > "$upg_log"

        ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip_objetivo "DEBIAN_FRONTEND=noninteractive apt-get autoremove -y && DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y; echo ''; echo '✅ $L_UPG_DONE'" >> "$upg_log" 2>&1 &
        local ssh_pid=$!

        sleep 1
        less -R +F "$upg_log"
        
        if kill -0 $ssh_pid 2>/dev/null; then
            echo -e "\n  ⏳ $L_WAIT_BG"
            wait $ssh_pid 2>/dev/null
        fi
        rm -f "$upg_log"

        clear
        if [ ${#vms[@]} -gt 0 ]; then
            echo "========================================================================================="
            echo "      🏁 $L_EVAC_SUMMARY: $objetivo"
            echo "========================================================================================="
            for id in "${vms[@]}"; do
                printf "  VM %-5s %-18s : %s\n" "$id" "[${vm_names[$id]:0:16}]" "${vm_status[$id]}"
            done
            echo "========================================================================================="
        fi
        echo -e "\n  📦 $L_PHASE $fase: $L_UPG_PHASE_DONE"

        echo "---------------------------------------------------"
        echo "  s) 💻 $L_OPEN_SHELL"
        echo "  n) ⏭️  $L_CONT_SUMMARY"
        echo "---------------------------------------------------"
        read -p "  $L_OPEN_SHELL_Q $objetivo? [s/n]: " open_shell
        if [[ "$open_shell" =~ ^[sS] ]]; then
            echo "  $L_CONNECTING"
            ssh -q -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip_objetivo "bash"
        fi
        ((fase++))
    fi

    if [[ "$plan" == *2* ]]; then
        echo -e "\n  🔔 $L_UPG_NOTICE $objetivo $L_UPG_NOTICE_2"
        echo "---------------------------------------------------"
        pedir_confirmacion "$L_REBOOT_Q $objetivo $L_REBOOT_Q_NOW"
        if [ $? -eq 0 ]; then
            local vms_running=($(pvesh get /nodes/$objetivo/qemu --output-format json 2>/dev/null | jq -r '.[] | select(.status == "running") | .vmid' 2>/dev/null))
            local proceder_reinicio=true

            if [ ${#vms_running[@]} -gt 0 ]; then
                echo -e "\n  ⚠️  \e[1;31m$L_WARN_CRIT\e[0m"
                echo "  ${#vms_running[@]} $L_VMS_RUNNING_WARN $objetivo."
                echo "  $L_REBOOT_WARN"
                echo "---------------------------------------------------"
                pedir_confirmacion "$L_SURE_REBOOT $objetivo?"
                if [ $? -ne 0 ]; then
                    proceder_reinicio=false
                fi
            fi

            if $proceder_reinicio; then
                echo -e "\n  🚀 $L_REBOOT_ISSUE $objetivo..."
                registrar_log "REBOOT" "Reinicio emitido a $objetivo tras mantenimiento"
                
                rm -rf "$DIR_CANDADO" ; rm -f "$ARCHIVO_TAREA" "/etc/pve/.gestor_targets_$objetivo"
                if [ "$objetivo" == "$NODO_LOCAL" ]; then
                    reboot
                    exit 0
                else
                    ssh $SSH_OPTS root@$ip_objetivo "reboot"
                    echo "  ✅ $L_ORDER_SENT"
                    sleep 2
                    return
                fi
            else
                echo "  $L_REBOOT_CANC"
            fi
        fi
    fi

    rm -rf "$DIR_CANDADO" ; rm -f "$ARCHIVO_TAREA" "/etc/pve/.gestor_targets_$objetivo"
    registrar_log "OK" "FIN MANTENIMIENTO"
    pausa_volver
}

# =================================================================
# 6. MENÚS Y SINCRONIZACIÓN
# =================================================================

cambiar_idioma() {
    clear
    echo "==================================================="
    echo "  Select your language / Selecciona tu idioma:"
    echo "  1) English"
    echo "  2) Español"
    echo "---------------------------------------------------"
    echo "  0) $L_BACK_MENU"
    echo "==================================================="
    read -p "  [1/2/0]: " lang_choice
    if [ "$lang_choice" == "1" ]; then
        echo "en" > "$ARCHIVO_LANG"
        LANG_ID="en"
    elif [ "$lang_choice" == "2" ]; then
        echo "es" > "$ARCHIVO_LANG"
        LANG_ID="es"
    fi
    cargar_idioma
}

propagar_script_cluster() {
    clear
    echo "==================================================="
    echo "      🔄 $L_PROPAGATING"
    echo "==================================================="
    # Buscamos TODOS los nodos excepto el local de forma exacta
    local nodos=$(obtener_lista_nodos "--excluir-local")
    local total=$(echo "$nodos" | wc -w)
    local i=0

    for n in $nodos; do
        ((i++))
        printf "\r  ⏳ [%-d/%-d] $L_SYNCING: \e[36m%-15s\e[0m" "$i" "$total" "$n"
        local ip=$(obtener_ip_nodo "$n")
        if [ -n "$ip" ]; then
            if scp $SSH_OPTS "$0" "root@$ip:/usr/local/sbin/gestor_nodos.sh" && ssh $SSH_OPTS root@$ip "chmod +x /usr/local/sbin/gestor_nodos.sh && rm -f /usr/local/sbin/gestor_nodos"; then
                registrar_log "OK" "Script sincronizado en $n"
            else
                registrar_log "FAIL" "Fallo de sincronización en $n"
            fi
        else
            printf "\n  ⚠️  $L_NO_IP %s. Revisa la red.\n" "$n"
        fi
    done
    echo -e "\n\n  ✅ $L_SYNC_DONE"
    pausa_volver
}

modulo_mantenimiento() {
    local objetivo="$NODO_OBJETIVO"

    # Autodetectar VMs encendidas y apagadas
    local vms_running=($(pvesh get /nodes/$objetivo/qemu --output-format json 2>/dev/null | jq -r '.[] | select(.status == "running") | .vmid' 2>/dev/null))
    local vms_stopped=($(pvesh get /nodes/$objetivo/qemu --output-format json 2>/dev/null | jq -r '.[] | select(.status != "running") | .vmid' 2>/dev/null))
    local vms=("${vms_running[@]}")

    clear
    echo "==================================================="
    echo "      🛠️  $L_MAINT_OPT: $objetivo"
    echo "==================================================="
    echo "  $L_SEL_TASKS:"
    echo "  1) $L_MIG_RUNNING (${#vms_running[@]} $L_DETECTED)"
    echo "  2) $L_UPG_NODE"
    echo "  0) $L_RET_MAIN"
    echo "---------------------------------------------------"
    read -p "  $L_TASKS_EXEC [12]: " plan

    # Control de salida explícita
    if [[ "$plan" == "0" || "$plan" == *0* ]]; then
        echo "  $L_RETURNING"
        sleep 1; return
    fi

    plan=${plan:-12}            # Por defecto aplica todas si pulsas Enter
    plan="${plan//[^1-2]/}"     # Filtra cualquier cosa que no sea 1 o 2

    if [ -z "$plan" ]; then
        echo "  $L_NO_VALID_TASK"
        sleep 1; return
    fi

    local do_mig=false; local do_up=false
    if [[ "$plan" == *1* ]]; then do_mig=true; fi
    if [[ "$plan" == *2* ]]; then do_up=true; fi

    if $do_mig && [ ${#vms_stopped[@]} -gt 0 ]; then
        echo "---------------------------------------------------"
        echo "  s) ✅ $L_YES_INC_STOPPED ${#vms_stopped[@]} VMs"
        echo "  n) ❌ $L_NO_ONLY_RUNNING"
        echo "---------------------------------------------------"
        read -p "  $L_INC_STOPPED_Q [s/n]: " inc_stopped
        if [[ "$inc_stopped" =~ ^[sS] ]]; then
            vms+=("${vms_stopped[@]}")
        fi
    fi

    if [ "$objetivo" == "$NODO_LOCAL" ] && $do_up; then
        clear
        echo "==================================================="
        echo "      ⚠️  $L_DENIED"
        echo "==================================================="
        echo "  $L_NO_MASS_UPG"
        echo "  $L_NO_MASS_UPG_2"
        echo ""
        echo "  👉 $L_LOGIN_OTHER"
        printf "     $L_SELECT_THERE \e[1;33m%s\e[0m.\n" "$objetivo"
        echo "---------------------------------------------------"
        pausa_volver
        return
    fi

    # --- RESOLUCIÓN DE DESTINOS Y HUÉRFANAS ---
    local -A target_map
    local -a vms_final=()
    local -a orphan_vms=()
    local repl_json=$(pvesh get /cluster/replication --output-format json 2>/dev/null)
    local res_json=$(pvesh get /cluster/resources --output-format json 2>/dev/null)
    
    local -A orphan_reason=()
    if $do_mig && [ ${#vms[@]} -gt 0 ]; then
        local -A rep_committed_ram=()
        for vmid in "${vms[@]}"; do
            local target=$(echo "$repl_json" | jq -r ".[] | select((.guest | tostring) == \"$vmid\") | .target" 2>/dev/null | head -n 1)
            if [ -n "$target" ]; then
                local vm_maxmem=$(echo "$res_json" | jq -r ".[] | select(.id == \"qemu/$vmid\") | .maxmem // 0" 2>/dev/null)
                local t_maxmem=$(echo "$res_json" | jq -r ".[] | select(.type == \"node\" and .node == \"$target\") | .maxmem // 0" 2>/dev/null)
                local t_allocated=$(echo "$res_json" | jq -r "[.[] | select(.type == \"qemu\" and .node == \"$target\") | .maxmem // 0] | add // 0" 2>/dev/null)
                
                local c_ram=${rep_committed_ram[$target]:-0}
                local future_allocated=$(( t_allocated + c_ram + vm_maxmem ))
                local limit=$(( t_maxmem * 9 / 10 ))
                
                if [ "$t_maxmem" -gt 0 ] && [ "$future_allocated" -gt "$limit" ]; then
                    orphan_vms+=("$vmid") # RAM destino saturada (>90%), calculamos destino alternativo
                    orphan_reason[$vmid]="$L_RAM_FULL ($target)"
                else
                    target_map[$vmid]=$target
                    vms_final+=("$vmid")
                    rep_committed_ram[$target]=$(( c_ram + vm_maxmem ))
                fi
            else
                orphan_vms+=("$vmid")
                orphan_reason[$vmid]="$L_NO_REPL"
            fi
        done
        
        if [ ${#orphan_vms[@]} -gt 0 ]; then
            clear
            echo "==================================================="
            echo "      ⚠️  $L_VMS_NEED_CALC"
            echo "==================================================="
            echo "  $L_CALC_DEST"
            echo "---------------------------------------------------"
            printf "  %-5s | %-15s | %-16s | %-7s | %-8s | %-10s | %s\n" "VMID" "$L_NAME" "$L_REASON" "RAM" "LOCAL" "$L_PROPOSAL" "$L_REMAINING"
            echo "---------------------------------------------------"
            
            local all_nodes=$(obtener_lista_nodos)
            local -A orphan_proposed=()
            local -A committed_ram=()
            for k in "${!rep_committed_ram[@]}"; do committed_ram[$k]=${rep_committed_ram[$k]}; done
            local -A committed_disk=()
            
            for vmid in "${orphan_vms[@]}"; do
                local name=$(echo "$res_json" | jq -r ".[] | select(.id == \"qemu/$vmid\") | .name" 2>/dev/null)
                if [ -z "$name" ]; then name="?"; fi
                local maxdisk=$(echo "$res_json" | jq -r ".[] | select(.id == \"qemu/$vmid\") | .maxdisk // 0" 2>/dev/null)
                local maxdisk_gb=$((maxdisk / 1073741824))
                
                local maxmem=$(echo "$res_json" | jq -r ".[] | select(.id == \"qemu/$vmid\") | .maxmem // 0" 2>/dev/null)
                local maxmem_gb=$((maxmem / 1073741824))
                if [ "$maxmem_gb" -eq 0 ]; then maxmem_gb="<1"; fi

                # EXTRAER TODOS LOS DISCOS Y SUMAR ESPACIO REQUERIDO POR DATASTORE
                local disks=$(pvesh get /nodes/$objetivo/qemu/$vmid/config --output-format json 2>/dev/null | jq -r 'to_entries | map(select(.key | test("^(ide|scsi|sata|virtio)[0-9]+$")) | select(.value | contains("cdrom") | not) | .value) | .[]')
                
                unset vm_req_storage
                declare -A vm_req_storage=()
                local ds_list=""
                local total_local_gb=0

                for disk in $disks; do
                    local st_name=$(echo "$disk" | cut -d':' -f1)
                    local shared=$(echo "$res_json" | jq -r ".[] | select(.type == \"storage\" and .storage == \"$st_name\" and .node == \"$objetivo\") | .shared // 0" | head -n 1)
                    
                    if [ "$shared" == "1" ]; then
                        vm_req_storage["$st_name"]=0
                    else
                        local size_gb=0
                        if [[ "$disk" =~ size=([0-9]+)([KMGTP]?) ]]; then
                            local val="${BASH_REMATCH[1]}"
                            local unit="${BASH_REMATCH[2]}"
                            case "$unit" in
                                T) size_gb=$((val * 1024)) ;;
                                G) size_gb=$val ;;
                                M|K) size_gb=1 ;;
                                *) size_gb=$((val / 1073741824)) ;;
                            esac
                        else
                            size_gb=1 # Valor fallback de seguridad
                        fi
                        vm_req_storage["$st_name"]=$(( ${vm_req_storage["$st_name"]:-0} + size_gb ))
                        total_local_gb=$((total_local_gb + size_gb))
                    fi
                done

                for st in "${!vm_req_storage[@]}"; do ds_list+="$st,"; done
                ds_list="${ds_list%,}"
                if [ -z "$ds_list" ]; then ds_list="None"; fi
                
                local best_node=""
                local max_free=-1
                local final_free_ram_gb="0"
                local final_free_disk_gb="0"
                local final_free_ram_pct="0"
                local final_free_disk_str=""
                
                for n in $all_nodes; do
                    if [ "$n" == "$objetivo" ]; then continue; fi
                    local n_status=$(echo "$res_json" | jq -r ".[] | select(.type == \"node\" and .node == \"$n\") | .status" 2>/dev/null)
                    if [ "$n_status" != "online" ]; then continue; fi
                    
                    local node_valid=true
                    local worst_future_disk=-1
                    local worst_pct=100
                    
                    local n_maxmem=$(echo "$res_json" | jq -r ".[] | select(.type == \"node\" and .node == \"$n\") | .maxmem" 2>/dev/null)
                    # Calcular RAM prometida a las VMs que YA existen en ese nodo
                    local n_allocated_ram=$(echo "$res_json" | jq -r "[.[] | select(.type == \"qemu\" and .node == \"$n\") | .maxmem // 0] | add // 0" 2>/dev/null)
                    if [ -z "$n_maxmem" ] || [ "$n_maxmem" == "null" ]; then n_maxmem=0; fi
                    
                    # Aplicar consumo acumulado de VMs previas en este bucle
                    local c_ram=${committed_ram[$n]:-0}
                    local c_disk=${committed_disk["$n:$storage"]:-0}
                    
                    local future_disk=$((s_avail - c_disk - maxdisk))
                    local thresh_disk=$((s_max / 10))
                    
                    local future_ram=$((n_maxmem - n_allocated_ram - c_ram - maxmem))
                    local thresh_ram=$((n_maxmem / 10))
                    
                    if [ "$future_ram" -lt "$thresh_ram" ]; then
                        node_valid=false
                    fi
                    
                    if $node_valid; then
                        for st in "${!vm_req_storage[@]}"; do
                            local req_gb=${vm_req_storage[$st]}
                            local req_bytes=$((req_gb * 1073741824))
                            
                            local st_json=$(pvesh get /nodes/$n/storage/$st/status --output-format json 2>/dev/null)
                            if [ -z "$st_json" ] || [ "$st_json" == "null" ]; then node_valid=false; break; fi
                            
                            local s_max=$(echo "$st_json" | jq -r '.total // 0')
                            local s_avail=$(echo "$st_json" | jq -r '.avail // 0')
                            
                            if [ "$s_max" -eq 0 ]; then node_valid=false; break; fi
                            
                            if [ "$req_gb" -gt 0 ]; then
                                local c_disk=${committed_disk["$n:$st"]:-0}
                                local future_disk=$((s_avail - c_disk - req_bytes))
                                local thresh_disk=$((s_max / 10))
                                
                                if [ "$future_disk" -lt "$thresh_disk" ]; then node_valid=false; break; fi
                                
                                local future_disk_pct=$(( s_max > 0 ? (future_disk * 100 / s_max) : 0 ))
                                if [ "$worst_future_disk" -eq -1 ] || [ "$future_disk" -lt "$worst_future_disk" ]; then
                                    worst_future_disk=$future_disk
                                    worst_pct=$future_disk_pct
                                fi
                            fi
                        done
                    fi
                    
                    if $node_valid; then
                        local score=$worst_future_disk
                        if [ "$score" -eq -1 ]; then score=$future_ram; fi # Si solo hay NAS, puntúa por RAM
                        
                        if [ "$score" -gt "$max_free" ]; then
                            max_free=$score
                            best_node=$n
                            final_free_ram_gb=$((future_ram / 1073741824))
                            final_free_ram_pct=$(( n_maxmem > 0 ? (future_ram * 100 / n_maxmem) : 0 ))
                            if [ "$worst_future_disk" -eq -1 ]; then
                                final_free_disk_str="SHARED"
                            else
                                final_free_disk_str="$((worst_future_disk / 1073741824))G(${worst_pct}%)"
                            fi
                        fi
                    fi
                done
                
                if [ -z "$best_node" ]; then
                    best_node="❌ $L_NO_RESOURCES"
                    printf "  %-5s | %-15s | %-16s | %-4s GB | %-5s GB | %-10s | %s\n" "$vmid" "${name:0:15}" "${orphan_reason[$vmid]:0:16}" "$maxmem_gb" "$total_local_gb" "$best_node" "-"
                else
                    orphan_proposed[$vmid]=$best_node
                    committed_ram[$best_node]=$(( ${committed_ram[$best_node]:-0} + maxmem ))
                    for st in "${!vm_req_storage[@]}"; do
                        local req_gb=${vm_req_storage[$st]}
                        if [ "$req_gb" -gt 0 ]; then
                            local req_bytes=$((req_gb * 1073741824))
                            committed_disk["$best_node:$st"]=$(( ${committed_disk["$best_node:$st"]:-0} + req_bytes ))
                        fi
                    done
                    printf "  %-5s | %-15s | %-16s | %-4s GB | %-5s GB | %-10s | %s\n" "$vmid" "${name:0:15}" "${orphan_reason[$vmid]:0:16}" "$maxmem_gb" "$total_local_gb" "$best_node" "${final_free_ram_gb}G(${final_free_ram_pct}%) / ${final_free_disk_str}"
                fi
            done
            
            # DIBUJAR RESUMEN FINAL ACUMULADO
            local -A summary_nodes=()
            for bn in "${orphan_proposed[@]}"; do
                if [[ "$bn" != "❌"* ]]; then summary_nodes[$bn]=1; fi
            done
            
            if [ ${#summary_nodes[@]} -gt 0 ]; then
                echo "---------------------------------------------------"
                echo "  📊 IMPACTO ACUMULADO EN DESTINOS (Tras migración)"
                for n in "${!summary_nodes[@]}"; do
                    local n_maxmem=$(echo "$res_json" | jq -r ".[] | select(.type == \"node\" and .node == \"$n\") | .maxmem" 2>/dev/null)
                    local n_allocated_ram=$(echo "$res_json" | jq -r "[.[] | select(.type == \"qemu\" and .node == \"$n\") | .maxmem // 0] | add // 0" 2>/dev/null)
                    local c_ram=${committed_ram[$n]:-0}
                    local f_ram=$((n_maxmem - n_allocated_ram - c_ram))
                    local f_ram_gb=$((f_ram / 1073741824))
                    local f_ram_pct=$(( n_maxmem > 0 ? (f_ram * 100 / n_maxmem) : 0 ))
                    
                    printf "  ► %-10s RAM Asignable Libre: %sG (%s%%)\n" "$n" "$f_ram_gb" "$f_ram_pct"
                    for k in "${!committed_disk[@]}"; do
                        if [[ "$k" == "$n:"* ]]; then
                            local st=${k#*:}
                            local st_json=$(pvesh get /nodes/$n/storage/$st/status --output-format json 2>/dev/null)
                            local s_max=$(echo "$st_json" | jq -r '.total // 0')
                            local s_avail=$(echo "$st_json" | jq -r '.avail // 0')
                            local c_disk=${committed_disk[$k]}
                            local f_disk=$((s_avail - c_disk))
                            local f_disk_gb=$((f_disk / 1073741824))
                            local f_disk_pct=$(( s_max > 0 ? (f_disk * 100 / s_max) : 0 ))
                            
                            if [ "$f_disk_gb" -gt 1024 ]; then
                                local f_disk_tb=$(awk "BEGIN {printf \"%.2f\", $f_disk_gb/1024}")
                                printf "    └─ %-7s Disco Libre: %sT (%s%%)\n" "$st" "$f_disk_tb" "$f_disk_pct"
                            else
                                printf "    └─ %-7s Disco Libre: %sG (%s%%)\n" "$st" "$f_disk_gb" "$f_disk_pct"
                            fi
                        fi
                    done
                done
            fi
            
            echo "---------------------------------------------------"
            echo "   $L_MIG_DECISION"
            echo "  - $L_WRITE_IDS"
            echo "  - $L_WRITE_ALL"
            echo "  - $L_WRITE_ZERO"
            echo "---------------------------------------------------"
            read -p "  $L_SELECTION: " orphan_sel
            
            if [[ "${orphan_sel,,}" == "all" || "${orphan_sel,,}" == "todos" ]]; then
                for vmid in "${orphan_vms[@]}"; do
                    if [[ -n "${orphan_proposed[$vmid]}" && "${orphan_proposed[$vmid]}" != "❌"* ]]; then
                        target_map[$vmid]=${orphan_proposed[$vmid]}
                        vms_final+=("$vmid")
                    fi
                done
            elif [[ "$orphan_sel" != "0" && -n "$orphan_sel" ]]; then
                for id in $orphan_sel; do
                    if [[ -n "${orphan_proposed[$id]}" && "${orphan_proposed[$id]}" != "❌"* ]]; then
                        target_map[$id]=${orphan_proposed[$id]}
                        vms_final+=("$id")
                    fi
                done
            fi
        fi

        > "/etc/pve/.gestor_targets_$objetivo"
        for vmid in "${vms_final[@]}"; do
            echo "$vmid:${target_map[$vmid]}" >> "/etc/pve/.gestor_targets_$objetivo"
        done
        vms=("${vms_final[@]}")
    fi

    # --- VISTA PREVIA ---
    clear
    echo "==================================================="
    echo "      🚀 $L_MAINT_PREV: $objetivo"
    echo "==================================================="
    if $do_mig && [ ${#vms[@]} -gt 0 ]; then
        echo "  - $L_VMS_TO_MIG:   ${#vms[@]}"
        for vmid in "${vms[@]}"; do
            local name=$(echo "$res_json" | jq -r ".[] | select(.id == \"qemu/$vmid\") | .name" 2>/dev/null)
            if [ -z "$name" ]; then name="?"; fi
            local target="${target_map[$vmid]}"
            
            local maxmem=$(echo "$res_json" | jq -r ".[] | select(.id == \"qemu/$vmid\") | .maxmem // 0" 2>/dev/null)
            local maxdisk=$(echo "$res_json" | jq -r ".[] | select(.id == \"qemu/$vmid\") | .maxdisk // 0" 2>/dev/null)
            local mem_gb=$((maxmem / 1073741824))
            local disk_gb=$((maxdisk / 1073741824))
            if [ "$mem_gb" -eq 0 ] && [ "$maxmem" -gt 0 ]; then mem_gb="<1"; fi
            if [ "$disk_gb" -eq 0 ] && [ "$maxdisk" -gt 0 ]; then disk_gb="<1"; fi

            printf "    🔸 VM %-5s %-18s : %-12s -> %-10s | %s: %-4s GB | %s: %-5s GB\n" "$vmid" "[${name:0:16}]" "$objetivo" "$target" "$L_RAM" "${mem_gb}" "$L_DISK" "${disk_gb}"
        done
    elif $do_mig; then
        echo "  - $L_VMS_TO_MIG:   0"
    else
        echo "  - $L_VMS_TO_MIG:   $L_OMITTED"
    fi
    $do_up  && echo "  - $L_UPGRADE_APT: $L_YES_DIST" || echo "  - $L_UPGRADE_APT: $L_OMITTED"
    
    local simultaneas=1
    local mode_concurrency=1
    if $do_mig && [ ${#vms[@]} -gt 1 ]; then
        echo "---------------------------------------------------"
        echo "  ⚡ $L_CONCURRENCY"
        echo "  1) 🐢 $L_CONC_SINGLE"
        echo "  2) 🧠 $L_CONC_SMART"
        echo "  3) 🚀 $L_CONC_MANUAL"
        echo "---------------------------------------------------"
        read -p "  $L_SELECTION [1/2/3]: " mode_concurrency
        if [[ "$mode_concurrency" == "3" ]]; then
            read -p "  $L_SIMULTANEOUS (1-${#vms[@]}): " simultaneas
            simultaneas=${simultaneas:-1}
            if [[ ! "$simultaneas" =~ ^[0-9]+$ ]]; then simultaneas=1; fi
            if [ "$simultaneas" -gt "${#vms[@]}" ]; then simultaneas=${#vms[@]}; fi
            if [ "$simultaneas" -lt 1 ]; then simultaneas=1; fi
        elif [[ "$mode_concurrency" == "2" ]]; then
            simultaneas=${#vms[@]}
        else
            mode_concurrency=1
            simultaneas=1
        fi
    fi
    
    echo "---------------------------------------------------"
    pedir_confirmacion "$L_PROC_MAINT" || { rm -f "/etc/pve/.gestor_targets_$objetivo"; return; }
    
    # Si no se elige migrar, vaciamos la lista de VMs para no moverlas
    ! $do_mig && vms=()

    # Registrar las VMs originales para no traer VMs de otros nodos por error
    if [ ${#vms[@]} -gt 0 ]; then
        local vms_a_guardar=("${vms[@]}")
        if [ -f "/etc/pve/.vms_origen_$objetivo" ]; then
            local existing_vms=($(cat "/etc/pve/.vms_origen_$objetivo"))
            vms_a_guardar=($(echo "${vms_a_guardar[@]}" "${existing_vms[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
        fi
        echo "${vms_a_guardar[@]}" > "/etc/pve/.vms_origen_$objetivo"
    fi

    ejecutar_mantenimiento "$objetivo" "$plan" "$simultaneas" "$mode_concurrency" "${vms[@]}"
}

modulo_recuperacion() {
    while true; do
    local -A target_map
    target_map=()
    local -a all_pending_vms=()
    local -A node_pending_count
    node_pending_count=()

    for f in /etc/pve/.vms_origen_*; do
        [ -f "$f" ] || continue
        local target_node=$(basename "$f" | sed 's/.vms_origen_//')
        local file_vms=($(cat "$f" 2>/dev/null))
        for vmid in "${file_vms[@]}"; do
            if [[ "$vmid" =~ ^[0-9]+$ ]]; then
                target_map[$vmid]=$target_node
                all_pending_vms+=("$vmid")
                node_pending_count[$target_node]=$(( ${node_pending_count[$target_node]:-0} + 1 ))
            fi
        done
    done

        local res_json=$(pvesh get /cluster/resources --output-format json 2>/dev/null)
        local title_msg="$L_NODES_PENDING"
        local -a recorded_pending_vms=("${all_pending_vms[@]}")

    if [ ${#all_pending_vms[@]} -eq 0 ]; then
            local repl_json=$(pvesh get /cluster/replication --output-format json 2>/dev/null)
            local repl_to_local=$(echo "$repl_json" | jq -r ".[] | select(.target == \"$NODO_LOCAL\") | .guest" 2>/dev/null)
            
            for vmid in $repl_to_local; do
                local current_node=$(echo "$res_json" | jq -r ".[] | select(.id == \"qemu/$vmid\") | .node" 2>/dev/null)
                if [ -n "$current_node" ] && [ "$current_node" != "null" ] && [ "$current_node" != "$NODO_LOCAL" ]; then
                    target_map[$vmid]=$NODO_LOCAL
                    all_pending_vms+=("$vmid")
                    node_pending_count[$NODO_LOCAL]=$(( ${node_pending_count[$NODO_LOCAL]:-0} + 1 ))
                fi
            done

            if [ ${#all_pending_vms[@]} -eq 0 ]; then
                clear
                echo "==================================================="
                echo "      📥 $L_RECOVER_VMS"
                echo "==================================================="
                echo "  ✅ $L_NO_PENDING"
                echo "  $L_NO_RECORDS"
                echo "  $L_NO_MANUAL_REPL"
                pausa_volver
                return
            else
                title_msg="$L_MANUAL_CANDIDATES"
            fi
    fi

    local -A pending_vm_names
    pending_vm_names=()
    local -A pending_vm_nodes
    pending_vm_nodes=()
    local -A pending_vm_ram=()
    local -A pending_vm_disk=()
    for vmid in "${all_pending_vms[@]}"; do
        local current_node=$(echo "$res_json" | jq -r ".[] | select(.id == \"qemu/$vmid\") | .node" 2>/dev/null)
        if [ -z "$current_node" ] || [ "$current_node" == "null" ]; then current_node="?"; fi
        local name=$(echo "$res_json" | jq -r ".[] | select(.id == \"qemu/$vmid\") | .name" 2>/dev/null)
        if [ -z "$name" ] || [ "$name" == "null" ]; then name="?"; fi
        pending_vm_names[$vmid]=$name
        pending_vm_nodes[$vmid]=$current_node

        local maxmem=$(echo "$res_json" | jq -r ".[] | select(.id == \"qemu/$vmid\") | .maxmem // 0" 2>/dev/null)
        local maxdisk=$(echo "$res_json" | jq -r ".[] | select(.id == \"qemu/$vmid\") | .maxdisk // 0" 2>/dev/null)
        local mem_gb=$((maxmem / 1073741824))
        local disk_gb=$((maxdisk / 1073741824))
        if [ "$mem_gb" -eq 0 ] && [ "$maxmem" -gt 0 ]; then mem_gb="<1"; fi
        if [ "$disk_gb" -eq 0 ] && [ "$maxdisk" -gt 0 ]; then disk_gb="<1"; fi
        pending_vm_ram[$vmid]=$mem_gb
        pending_vm_disk[$vmid]=$disk_gb
    done

    clear
    echo "==================================================="
    echo "      📥 $L_RECOVER_VMS"
    echo "==================================================="
    if [ ${#recorded_pending_vms[@]} -eq 0 ]; then
        echo "  ✅ $L_NO_PENDING"
        echo "  $L_NO_RECORDS"
        echo "---------------------------------------------------"
    fi
    echo "  $title_msg"
    for node in "${!node_pending_count[@]}"; do
        printf "  - \e[36m%-10s\e[0m : %d VMs\n" "$node" "${node_pending_count[$node]}"
        for vmid in "${all_pending_vms[@]}"; do
            if [ "${target_map[$vmid]}" == "$node" ]; then
                printf "      🔸 ID: %-5s | %-18s | %-8s: %-10s | %s: %-4s GB | %s: %-5s GB\n" "$vmid" "[${pending_vm_names[$vmid]:0:16}]" "$L_CURRENT" "${pending_vm_nodes[$vmid]}" "$L_RAM" "${pending_vm_ram[$vmid]}" "$L_DISK" "${pending_vm_disk[$vmid]}"
            fi
        done
    done
    echo "---------------------------------------------------"
    echo "  📝 $L_REC_SELECTION"
    echo "  - $L_SEL_NODE_NAME"
    echo "  - $L_SEL_IDS"
    echo "  - $L_SEL_ALL"
    echo "  - $L_SEL_ZERO"
    echo "---------------------------------------------------"
    read -p "  $L_SELECTION: " input_sel
    
    if [[ "$input_sel" == "0" || -z "$input_sel" ]]; then echo "  $L_RETURNING"; sleep 1; return; fi
    
    local -a vms=()
    if [[ "${input_sel,,}" == "all" || "${input_sel,,}" == "todos" ]]; then
        vms=("${all_pending_vms[@]}")
    elif [ -n "${node_pending_count[$input_sel]}" ]; then
        for vmid in "${all_pending_vms[@]}"; do
            if [ "${target_map[$vmid]}" == "$input_sel" ]; then
                vms+=("$vmid")
            fi
        done
    else
        for id in $input_sel; do
            if [[ "$id" =~ ^[0-9]+$ ]] && [ -n "${target_map[$id]}" ]; then
                vms+=("$id")
            fi
        done
    fi

    if [ ${#vms[@]} -eq 0 ]; then
        echo "  ❌ $L_INVALID_SEL"
        sleep 2; continue
    fi

    if [ ${#vms[@]} -gt 0 ]; then
        local repl_json=$(pvesh get /cluster/replication --output-format json 2>/dev/null)
        
        local -a vms_stopped=()
        for vmid in "${vms[@]}"; do
            local st=$(echo "$res_json" | jq -r ".[] | select(.id == \"qemu/$vmid\") | .status" 2>/dev/null)
            if [ "$st" != "running" ]; then
                vms_stopped+=("$vmid")
            fi
        done
        
        if [ ${#vms_stopped[@]} -gt 0 ]; then
            clear
            echo "==================================================="
            echo "      ⚠️  $L_VMS_STOPPED_DET"
            echo "==================================================="
            echo "---------------------------------------------------"
            echo "  s) ✅ $L_YES_REC_STOPPED ${#vms_stopped[@]} VMs"
            echo "  n) ❌ $L_NO_ONLY_RUN_REC"
            echo "---------------------------------------------------"
            read -p "  $L_INC_STOPPED_REC_Q [s/n]: " inc_stopped
            if [[ ! "$inc_stopped" =~ ^[sS] ]]; then
                local -a temp_vms=()
                for vmid in "${vms[@]}"; do
                    if [[ ! " ${vms_stopped[*]} " =~ " ${vmid} " ]]; then
                        temp_vms+=("$vmid")
                    fi
                done
                vms=("${temp_vms[@]}")
            fi
        fi

        local -a vms_orphans=()
        for vmid in "${vms[@]}"; do
            local target=$(echo "$repl_json" | jq -r ".[] | select((.guest | tostring) == \"$vmid\") | .target" 2>/dev/null | head -n 1)
            if [ -z "$target" ]; then
                vms_orphans+=("$vmid")
            fi
        done

        if [ ${#vms_orphans[@]} -gt 0 ]; then
            clear
            echo "==================================================="
            echo "      ⚠️  $L_VMS_NO_REPL"
            echo "==================================================="
            echo "---------------------------------------------------"
            echo "  s) ✅ $L_YES_REC_ORPH ${#vms_orphans[@]} VMs"
            echo "  n) ❌ $L_NO_ONLY_REPL"
            echo "---------------------------------------------------"
            read -p "  $L_INC_ORPH_Q [s/n]: " inc_orphans
            if [[ ! "$inc_orphans" =~ ^[sS] ]]; then
                local -a temp_vms=()
                for vmid in "${vms[@]}"; do
                    if [[ ! " ${vms_orphans[*]} " =~ " ${vmid} " ]]; then
                        temp_vms+=("$vmid")
                    fi
                done
                vms=("${temp_vms[@]}")
            fi
        fi
        
        if [ ${#vms[@]} -eq 0 ]; then
            echo "  ❌ $L_NO_VMS_LEFT"
            sleep 2; continue
        fi
    fi

    # --- VISTA PREVIA ---
    clear
    echo "==================================================="
    echo "      📥 $L_PREV_REC_GLOBAL"
    echo "==================================================="
    echo "  - $L_VMS_TO_BRING: ${#vms[@]}"
    for vmid in "${vms[@]}"; do
        local dest_node="${target_map[$vmid]}"
        local current_node="${pending_vm_nodes[$vmid]}"
        local name="${pending_vm_names[$vmid]}"
        printf "    🔸 VM %-5s %-18s : %-12s -> %-10s | %s: %-4s GB | %s: %-5s GB\n" "$vmid" "[${name:0:16}]" "$current_node" "$dest_node" "$L_RAM" "${pending_vm_ram[$vmid]}" "$L_DISK" "${pending_vm_disk[$vmid]}"
    done
    echo "---------------------------------------------------"

    local -A rec_req_ram=()
    local -A rec_req_disk=()
    
    for vmid in "${vms[@]}"; do
        local dest_node="${target_map[$vmid]}"
        local current_node="${pending_vm_nodes[$vmid]}"
        if [ "$dest_node" != "$current_node" ]; then
            local maxmem=$(echo "$res_json" | jq -r ".[] | select(.id == \"qemu/$vmid\") | .maxmem // 0" 2>/dev/null)
            rec_req_ram[$dest_node]=$(( ${rec_req_ram[$dest_node]:-0} + maxmem ))
            if [[ " ${vms_orphans[*]} " =~ " ${vmid} " ]]; then
                local maxdisk=$(echo "$res_json" | jq -r ".[] | select(.id == \"qemu/$vmid\") | .maxdisk // 0" 2>/dev/null)
                rec_req_disk[$dest_node]=$(( ${rec_req_disk[$dest_node]:-0} + maxdisk ))
            fi
        fi
    done

    echo "  📊 $L_IMPACT_TITLE"
    local abort_recovery=false
    local -A dest_impact_nodes=()
    for vmid in "${vms[@]}"; do dest_impact_nodes[${target_map[$vmid]}]=1; done

    for n in "${!dest_impact_nodes[@]}"; do
        local n_maxmem=$(echo "$res_json" | jq -r ".[] | select(.type == \"node\" and .node == \"$n\") | .maxmem // 0" 2>/dev/null)
        local n_allocated_ram=$(echo "$res_json" | jq -r "[.[] | select(.type == \"qemu\" and .node == \"$n\") | .maxmem // 0] | add // 0" 2>/dev/null)
        local c_ram=${rec_req_ram[$n]:-0}
        local future_ram=$((n_maxmem - n_allocated_ram - c_ram))
        local future_ram_gb=$((future_ram / 1073741824))
        local future_ram_pct=$(( n_maxmem > 0 ? (future_ram * 100 / n_maxmem) : 0 ))
        local color_ram="\e[32m"
        if [ "$future_ram_pct" -lt 10 ]; then color_ram="\e[31m"; abort_recovery=true; fi
        printf "  ► %-10s %s: ${color_ram}%sG (%s%%)\e[0m\n" "$n" "$L_FUTURE_RAM" "$future_ram_gb" "$future_ram_pct"
        local c_disk=${rec_req_disk[$n]:-0}
        if [ "$c_disk" -gt 0 ]; then
            local c_disk_gb=$((c_disk / 1073741824))
            printf "    └─ ⚠️  $L_WARN_EXTRA_DISK\n" "$c_disk_gb" "$n"
        fi
    done
    echo "---------------------------------------------------"

    if $abort_recovery; then
        echo -e "  ❌ \e[31m$L_ERR_RAM_FULL\e[0m"
        echo "  $L_REDUCE_VMS"
        pausa_volver
        continue
    fi

    local simultaneas=1
    local mode_concurrency=1
    if [ ${#vms[@]} -gt 1 ]; then
        echo "  ⚡ $L_CONCURRENCY"
        echo "  1) 🐢 $L_CONC_SINGLE"
        echo "  2) 🧠 $L_CONC_SMART"
        echo "  3) 🚀 $L_CONC_MANUAL"
        echo "---------------------------------------------------"
        read -p "  $L_SELECTION [1/2/3]: " mode_concurrency
        if [[ "$mode_concurrency" == "3" ]]; then
            read -p "  $L_SIMULTANEOUS (1-${#vms[@]}): " simultaneas
            simultaneas=${simultaneas:-1}
            if [[ ! "$simultaneas" =~ ^[0-9]+$ ]]; then simultaneas=1; fi
            if [ "$simultaneas" -gt "${#vms[@]}" ]; then simultaneas=${#vms[@]}; fi
            if [ "$simultaneas" -lt 1 ]; then simultaneas=1; fi
        elif [[ "$mode_concurrency" == "2" ]]; then
            simultaneas=${#vms[@]}
        else
            mode_concurrency=1
            simultaneas=1
        fi
    fi
    pedir_confirmacion "$L_START_REC_Q" || continue

    declare -A vm_status
    declare -A vm_names
    for id in "${vms[@]}"; do
        vm_status[$id]="⏳ $L_PENDING"
        vm_names[$id]="${pending_vm_names[$id]}"
    done
    local mig_log=$(mktemp)
    > "$mig_log"

    local jobs_running=0
    local vms_done=0
    local -a pending_vms=("${vms[@]}")
    local -A vm_pid
    local -A active_targets=()
    local -A vm_target_node=()
    
    local sim_display="$simultaneas"
    if [[ "$mode_concurrency" == "2" ]]; then sim_display="$L_SMART"; fi

    printf "\e[2J\e[H"

    while [ $vms_done -lt ${#vms[@]} ]; do
        while [ $jobs_running -lt $simultaneas ] && [ ${#pending_vms[@]} -gt 0 ]; do
            local target_found=false
            local selected_idx=0
            local vmid=""
            local current_node=""
            
            for i in "${!pending_vms[@]}"; do
                vmid="${pending_vms[$i]}"
                current_node=$(pvesh get /cluster/resources --output-format json 2>/dev/null | jq -r ".[] | select(.id == \"qemu/$vmid\") | .node" 2>/dev/null)
                
                if [[ "$mode_concurrency" == "2" ]]; then
                    if [ -z "${active_targets[$current_node]}" ]; then
                        target_found=true
                        selected_idx=$i
                        break
                    fi
                else
                    target_found=true
                    selected_idx=$i
                    break
                fi
            done
            
            if ! $target_found; then
                break
            fi
            
            vmid="${pending_vms[$selected_idx]}"
            pending_vms=("${pending_vms[@]:0:$selected_idx}" "${pending_vms[@]:$((selected_idx + 1))}")
            
            current_node=$(pvesh get /cluster/resources --output-format json 2>/dev/null | jq -r ".[] | select(.id == \"qemu/$vmid\") | .node" 2>/dev/null)
            vm_target_node[$vmid]=$current_node
            active_targets[$current_node]=1
            
            local dest_node="${target_map[$vmid]}"
            
            if [ -z "$current_node" ]; then
                vm_status[$vmid]="❌ $L_NOT_FOUND"
                unset active_targets[$current_node]
                ((vms_done++))
                continue
            fi
            
            if [ "$current_node" == "$dest_node" ]; then
                vm_status[$vmid]="✅ $L_ALREADY_HERE"
                unset active_targets[$current_node]
                ((vms_done++))
                continue
            fi

            local is_locked=$(pvesh get /nodes/$current_node/qemu/$vmid/config --output-format json 2>/dev/null | jq -r '.lock // empty')
            if [ -n "$is_locked" ]; then
                vm_status[$vmid]="⚠️  $L_BLOCKED ($is_locked)"
                registrar_log "WARN" "Recuperación de VM $vmid omitida ($is_locked)"
                unset active_targets[$current_node]
                ((vms_done++))
                continue
            fi

            local ip_current=$(obtener_ip_nodo "$current_node")
            if [ -z "$ip_current" ]; then
                vm_status[$vmid]="❌ Error IP de $current_node"
                unset active_targets[$current_node]
                ((vms_done++))
                continue
            fi

            vm_status[$vmid]="🚀 $L_MIGRATING $dest_node..."
            registrar_log "MIGRATE" "Recuperando VM $vmid de $current_node a $dest_node"
            echo -e "\n=== MIGRACIÓN VM $vmid ($current_node -> $dest_node) ===" >> "$mig_log"

            (
                # Limpieza preventiva de snapshots ZFS huérfanos por migraciones canceladas
                local ip_target=$(obtener_ip_nodo "$dest_node")
                local zfs_clean="zfs list -H -o name -t snapshot 2>/dev/null | grep 'vm-${vmid}-.*@__migration__' | xargs -r zfs destroy 2>/dev/null || true"
                ssh $SSH_OPTS root@$ip_current "$zfs_clean"
                [ -n "$ip_target" ] && ssh $SSH_OPTS root@$ip_target "$zfs_clean"

                local vm_status_real=$(pvesh get /cluster/resources --output-format json 2>/dev/null | jq -r ".[] | select(.id == \"qemu/$vmid\") | .status" 2>/dev/null)
                local mig_cmd="qm migrate $vmid $dest_node --with-local-disks"
                if [ "$vm_status_real" == "running" ]; then
                    mig_cmd="qm migrate $vmid $dest_node --online --with-local-disks"
                fi
                ssh $SSH_OPTS root@$ip_current "$mig_cmd" 2>&1 | stdbuf -o0 tr '\r' '\n' | while IFS= read -r line; do
                    [ -z "$line" ] && continue
                    echo "$line" > "/tmp/.mig_latest_$vmid"
                    printf "[VM %s] %s\n" "$vmid" "$line" >> "$mig_log"
                done
                
                local check_node=$(pvesh get /cluster/resources --output-format json 2>/dev/null | jq -r ".[] | select(.id == \"qemu/$vmid\") | .node" 2>/dev/null)
                if [ "$check_node" == "$dest_node" ]; then
                    echo "OK" > "/tmp/.mig_status_$vmid"
                else
                    echo "FAIL" > "/tmp/.mig_status_$vmid"
                fi
            ) &
            vm_pid[$vmid]=$!
            ((jobs_running++))
        done

        chequear_hilos_migracion
        dibujar_dashboard_migracion "📥 $L_REC_PROG" "$sim_display" "${vms[@]}"
        
        echo -e "  [ $L_PRESS_C ]\e[K"
        echo -e "-----------------------------------------------------------------------------------------\e[K"
        echo -e "\e[J\c"
        local key=""
        read -t 1 -n 1 -s key
        if [[ "${key,,}" == "c" ]] && [ ${#pending_vms[@]} -gt 0 ]; then
            for cid in "${pending_vms[@]}"; do
                vm_status[$cid]="🛑 $L_CANCELLED_MIG"
                ((vms_done++))
            done
            pending_vms=()
        fi
    done

    # RESUMEN FINAL
    clear
    echo "==================================================="
    echo "      🏁 $L_FINAL_REC_SUM"
    echo "==================================================="
    for id in "${vms[@]}"; do
        printf "  VM %-5s %-18s : %s\n" "$id" "[${vm_names[$id]:0:16}]" "${vm_status[$id]}"
    done
    echo "==================================================="
    
    # Limpieza y actualización de archivos de origen
    local -A involved_nodes
    for vmid in "${vms[@]}"; do
        involved_nodes[${target_map[$vmid]}]=1
    done

    local -A new_node_vms
    for vmid in "${all_pending_vms[@]}"; do
            if [[ " ${recorded_pending_vms[*]} " =~ " ${vmid} " ]]; then
                local t_node="${target_map[$vmid]}"
                if [[ ! " ${vms[*]} " =~ " ${vmid} " ]]; then
                    new_node_vms[$t_node]+="$vmid "
                else
                    if [[ "${vm_status[$vmid]}" != "✅ $L_COMPLETED" && "${vm_status[$vmid]}" != "✅ $L_ALREADY_HERE" ]]; then
                        new_node_vms[$t_node]+="$vmid "
                    fi
                fi
        fi
    done

    local leftover_count=0
    for n in "${!involved_nodes[@]}"; do
        local remaining=$(echo "${new_node_vms[$n]}" | xargs)
        if [ -n "$remaining" ]; then
            echo "$remaining" > "/etc/pve/.vms_origen_$n"
            leftover_count=$((leftover_count + 1))
        else
            rm -f "/etc/pve/.vms_origen_$n"
        fi
    done

    if [ $leftover_count -eq 0 ] && [ ${#vms[@]} -eq ${#all_pending_vms[@]} ]; then
        echo -e "\n  ✅ $L_ALL_REC_DONE"
    else
        echo -e "\n  ⚠️  $L_SOME_PENDING"
    fi
    
    registrar_log "OK" "Recuperación global finalizada"
    while true; do
        echo "---------------------------------------------------"
        echo "  L) 📜 $L_SEE_LOG"
        echo "  C) 🔄 $L_CONT_REC"
        echo "  Enter/0) ↩️  $L_RET_MAIN"
        echo "---------------------------------------------------"
        read -p "  $L_SELECTION [L/C/Enter/0]: " ans_log
        if [[ "${ans_log,,}" == "l" ]]; then
            less -R -P " LOG DE MIGRACIONES (Navegar: Flechas | Salir: 'q') " "$mig_log"
        elif [[ "${ans_log,,}" == "c" ]]; then
            rm -f "$mig_log"
            continue 2
        else
            rm -f "$mig_log"
            return
        fi
    done
    done
}

limpiar_discos_huerfanos() {
    local objetivo="$1"
    local -a nodos_a_escanear=()
    if [ "$objetivo" == "ALL" ]; then
        nodos_a_escanear=($(obtener_lista_nodos))
    else
        nodos_a_escanear=("$objetivo")
    fi

    clear
    echo "========================================================================================="
    if [ "$objetivo" == "ALL" ]; then echo "      🔍 $L_ORPHAN_SEARCH: $L_FULL_CLUSTER"; else echo "      🔍 $L_ORPHAN_SEARCH: $objetivo"; fi
    echo "========================================================================================="
    echo "  ⏳ $L_QUERY_DB"
    
    # 1. Obtener TODOS los IDs de máquinas y contenedores del clúster
    local cluster_vms=$(pvesh get /cluster/resources --output-format json 2>/dev/null | jq -r '.[] | select(.type=="qemu" or .type=="lxc") | .vmid' | sort -u)
    local -A vm_exists
    for v in $cluster_vms; do vm_exists[$v]=1; done
    
    local -a orphan_nodes=()
    local -a orphan_vols=()
    local -a orphan_sizes=()
    local -a orphan_formats=()
    local total_bytes=0
    
    for current_node in "${nodos_a_escanear[@]}"; do
        echo -e "  ⏳ $L_QUERY_STORE \e[33m$current_node\e[0m..."
        local local_storages=$(pvesh get /nodes/$current_node/storage --output-format json 2>/dev/null | jq -r '.[] | select(.shared == 0) | .storage')
        
        for st in $local_storages; do
            printf "     └─ $L_SCAN_DS: \e[36m%s\e[0m...\n" "$st"
            local content_json=$(pvesh get /nodes/$current_node/storage/$st/content --output-format json 2>/dev/null)
            if [ -z "$content_json" ] || [ "$content_json" == "null" ]; then continue; fi
            
            local vols=$(echo "$content_json" | jq -c '.[] | select(.content=="images" or .content=="rootdir")')
            
            for vol in $vols; do
                local volid=$(echo "$vol" | jq -r '.volid')
                local size=$(echo "$vol" | jq -r '.size // 0')
                local format=$(echo "$vol" | jq -r '.format // "raw"')
                
                local vol_raw=$(echo "$volid" | cut -d':' -f2)
                local vmid=$(echo "$vol_raw" | grep -oE '^([0-9]+)/|^vm-([0-9]+)-|^base-([0-9]+)-|^subvol-([0-9]+)-' | grep -oE '[0-9]+' | head -n 1)
                
                if [ -n "$vmid" ]; then
                    if [ -z "${vm_exists[$vmid]}" ]; then
                        orphan_nodes+=("$current_node")
                        orphan_vols+=("$volid")
                        orphan_sizes+=("$size")
                        orphan_formats+=("$format")
                        total_bytes=$((total_bytes + size))
                    fi
                fi
            done
        done
    done
    
    if [ ${#orphan_vols[@]} -eq 0 ]; then
        echo -e "\n  ✅ $L_NO_ORPHANS"
        pausa_volver
        return
    fi
    
    local total_gb=$((total_bytes / 1073741824))
    if [ "$total_gb" -eq 0 ]; then total_gb="<1"; fi
    
    clear
    echo "========================================================================================="
    echo "      ⚠️  $L_ORPHANS_DETECTED"
    echo "========================================================================================="
    printf "  %-12s | %-45s | %-10s | %-10s\n" "$L_NODE" "VOLUMEN" "$L_FORMAT" "$L_SIZE"
    echo "-----------------------------------------------------------------------------------------"
    for i in "${!orphan_vols[@]}"; do
        local sz_gb=$((${orphan_sizes[$i]} / 1073741824))
        if [ "$sz_gb" -eq 0 ]; then sz_gb="<1"; fi
        printf "  %-12s | %-45s | %-10s | %-5s GB\n" "${orphan_nodes[$i]:0:12}" "${orphan_vols[$i]:0:45}" "${orphan_formats[$i]}" "$sz_gb"
    done
    echo "-----------------------------------------------------------------------------------------"
    echo "  $L_TOTAL_RECOV: ~ $total_gb GB"
    echo "-----------------------------------------------------------------------------------------"
    
    pedir_confirmacion "$L_DEL_PERM ${#orphan_vols[@]} $L_DISKS" || return
    
    echo -e "\n  🗑️  $L_DEL_DISKS"
    for i in "${!orphan_vols[@]}"; do
        local t_node="${orphan_nodes[$i]}"
        local t_vol="${orphan_vols[$i]}"
        local ip_target=$(obtener_ip_nodo "$t_node")
        echo "     └─ [$t_node] $L_FREEING $t_vol..."
        ssh $SSH_OPTS root@$ip_target "pvesm free $t_vol" 2>/dev/null
        registrar_log "INFO" "Disco huérfano $t_vol eliminado en $t_node"
    done
    
    echo -e "\n  ✅ $L_CLEAN_DONE $total_gb GB."
    pausa_volver
}

pedir_seleccion_nodo() {
    local allow_all="$1"
    local nodos=$(obtener_lista_nodos)
    local idx=1
    local -a n_arr=()
    clear
    echo "==================================================="
    echo "      🎯 $L_SEL_TARGET"
    echo "==================================================="
    for n in $nodos; do 
        n_arr+=("$n")
        printf "  %d) %s\n" "$idx" "$n"
        ((idx++))
    done
    echo "---------------------------------------------------"
    if [ "$allow_all" == "true" ]; then
        echo "  A) 🌐 $L_ALL_CLUSTER"
    fi
    echo "  0) $L_RET_MAIN"
    echo "---------------------------------------------------"
    read -p "  $L_SELECTION: " sel
    
    if [ "$allow_all" == "true" ] && [[ "${sel,,}" == "a" ]]; then
        NODO_OBJETIVO="ALL"
        return 0
    fi

    # Limpiar entrada de espacios o retornos de carro (\r) que rompen el array
    sel="${sel//[^0-9]/}"
    
    if [[ "$sel" == "0" ]]; then
        NODO_OBJETIVO=""
    elif [[ -n "$sel" && "$sel" -ge 1 && "$sel" -le "${#n_arr[@]}" ]]; then
        NODO_OBJETIVO="${n_arr[$((sel-1))]}"
    else
        echo "  ❌ $L_INVALID_OPT"
        sleep 1
        NODO_OBJETIVO=""
    fi
    return 0
}

# =================================================================
# 7. ARRANQUE (SIEMPRE EN ESPAÑOL)
# =================================================================

if [ -f "$ARCHIVO_TAREA" ]; then
    target=$(jq -r '.target' "$ARCHIVO_TAREA" 2>/dev/null)
    leader=$(jq -r '.leader' "$ARCHIVO_TAREA" 2>/dev/null)

    clear
    echo "==================================================="
    echo "      📢 $L_TASK_ACTIVE $target"
    echo "      👑 $L_LEADER_NODE $leader"
    echo "==================================================="
    echo "  $L_CLUSTER_DETECTS"
    echo "  $L_IF_INTERRUPTED"
    echo "  $L_UNLOCK"
    echo "---------------------------------------------------"
    echo "  s) 🔓 $L_YES_FORCE"
    echo "  Enter) 👁️  $L_NO_MONITOR"
    echo "---------------------------------------------------"
    read -p "  $L_SELECTION [s/Enter]: " force
    if [[ "$force" =~ ^[sS] ]]; then
        rm -rf "$DIR_CANDADO" 2>/dev/null
        rm -f "$ARCHIVO_TAREA" 2>/dev/null
        echo "  $L_LOCK_CLEARED"
        sleep 2
    else
        if [ "$leader" == "$NODO_LOCAL" ] || [ "$leader" == "none" ]; then tail -n 10 -f "$ARCHIVO_LOG"; else
            ip=$(obtener_ip_nodo "$leader")
            if [ -n "$ip" ]; then ssh -t $SSH_OPTS root@$ip "tail -n 10 -f $ARCHIVO_LOG"; else tail -n 10 -f "$ARCHIVO_LOG"; fi
        fi
        exit 0
    fi
fi

while true; do
    printf "\e[r"
    clear
    echo "==================================================="
    echo "          ⚙️  $L_MAIN_TITLE (v$VERSION)"
    echo -e "          \e[36mBy Iván Romero\e[0m"
    echo "==================================================="
    echo "  📍 $L_LOCAL_NODE: $NODO_LOCAL"
    echo "---------------------------------------------------"
    echo "  1) 🚀 $L_OPT_1"
    echo "  2) 📥 $L_OPT_2"
    echo "  3) 💾 $L_OPT_3"
    echo "  4) 📜 $L_OPT_4"
    echo "  5) 🔄 $L_OPT_5"
    echo "  6) 🌐 $L_OPT_6"
    echo "---------------------------------------------------"
    echo "  0) ❌ $L_OPT_0"
    echo "---------------------------------------------------"
    read -p "  $L_SELECTION: " opcion
    opcion="${opcion//[^0-9]/}" # Limpiar entrada
    case $opcion in
        1) pedir_seleccion_nodo; [[ -n "$NODO_OBJETIVO" ]] && modulo_mantenimiento ;;
        2) modulo_recuperacion ;;
        3) pedir_seleccion_nodo "true"; [[ -n "$NODO_OBJETIVO" ]] && limpiar_discos_huerfanos "$NODO_OBJETIVO" ;;
        4) mostrar_historial_cluster ;;
        5) propagar_script_cluster ;;
        6) cambiar_idioma ;;
        0) exit 0 ;;
                *) 
                    echo "  ❌ $L_INVALID_OPT"
                    sleep 1
                    ;;
    esac
done
