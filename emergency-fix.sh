#!/bin/bash

echo "🚨 Script de emergencia para problemas con docker-entrypoint.sh"
echo "=============================================================="

# Función para usar Dockerfile simple
use_simple_dockerfile() {
    echo "🔧 Cambiando a Dockerfile simple (sin entrypoint personalizado)..."
    
    # Hacer backup del Dockerfile original
    if [ -f "GrowDesk/frontend/Dockerfile" ]; then
        cp "GrowDesk/frontend/Dockerfile" "GrowDesk/frontend/Dockerfile.backup"
        echo "📋 Backup creado: Dockerfile.backup"
    fi
    
    # Usar el Dockerfile simple
    if [ -f "GrowDesk/frontend/Dockerfile.simple" ]; then
        cp "GrowDesk/frontend/Dockerfile.simple" "GrowDesk/frontend/Dockerfile"
        echo "✅ Dockerfile simple activado"
    else
        echo "❌ Dockerfile.simple no encontrado"
        return 1
    fi
}

# Función para restaurar Dockerfile original
restore_original_dockerfile() {
    echo "🔄 Restaurando Dockerfile original..."
    
    if [ -f "GrowDesk/frontend/Dockerfile.backup" ]; then
        cp "GrowDesk/frontend/Dockerfile.backup" "GrowDesk/frontend/Dockerfile"
        echo "✅ Dockerfile original restaurado"
    else
        echo "❌ No se encontró backup del Dockerfile original"
        return 1
    fi
}

# Función para limpiar y reconstruir con Dockerfile simple
emergency_rebuild() {
    echo "🚨 Iniciando reconstrucción de emergencia..."
    
    # Detener contenedores
    docker-compose down -v --remove-orphans 2>/dev/null || true
    
    # Usar Dockerfile simple
    use_simple_dockerfile
    
    # Limpiar imágenes del frontend
    docker rmi $(docker images | grep growdesk.*frontend | awk '{print $3}') 2>/dev/null || true
    
    # Reconstruir solo el frontend
    echo "🔨 Reconstruyendo frontend con Dockerfile simple..."
    if docker-compose build --no-cache frontend; then
        echo "✅ Frontend reconstruido exitosamente"
        
        # Iniciar servicios
        echo "🚀 Iniciando servicios..."
        docker-compose up -d
        
        # Verificar estado
        sleep 10
        echo "📊 Estado de contenedores:"
        docker-compose ps
        
        # Verificar logs del frontend
        echo "📋 Logs del frontend:"
        docker-compose logs --tail=20 frontend
        
    else
        echo "❌ Error en reconstrucción de emergencia"
        return 1
    fi
}

# Función para verificar si el problema persiste
check_frontend_status() {
    echo "🔍 Verificando estado del frontend..."
    
    # Esperar un momento para que el contenedor se inicie
    sleep 5
    
    # Verificar si el contenedor está ejecutándose
    if docker-compose ps frontend | grep -q "Up"; then
        echo "✅ Contenedor frontend está ejecutándose"
        
        # Intentar acceder al servicio
        if curl -f http://localhost:3001 > /dev/null 2>&1; then
            echo "✅ Frontend accesible en http://localhost:3001"
        else
            echo "⚠️ Frontend ejecutándose pero no accesible en puerto 3001"
            echo "📋 Verificando logs..."
            docker-compose logs --tail=10 frontend
        fi
    else
        echo "❌ Contenedor frontend no está ejecutándose"
        echo "📋 Estado actual:"
        docker-compose ps frontend
        echo "📋 Logs de error:"
        docker-compose logs --tail=20 frontend
    fi
}

# Menú principal
main() {
    echo "🚀 ¿Qué deseas hacer?"
    echo "1) Reconstrucción de emergencia (usar Dockerfile simple)"
    echo "2) Verificar estado actual del frontend"
    echo "3) Usar Dockerfile simple (sin reconstruir)"
    echo "4) Restaurar Dockerfile original"
    echo "5) Ver logs del frontend"
    echo "6) Salir"
    
    read -p "Selecciona una opción (1-6): " choice
    
    case $choice in
        1)
            emergency_rebuild
            check_frontend_status
            ;;
        2)
            check_frontend_status
            ;;
        3)
            use_simple_dockerfile
            echo "✅ Dockerfile simple activado. Ejecuta 'docker-compose build frontend' para aplicar"
            ;;
        4)
            restore_original_dockerfile
            ;;
        5)
            echo "📋 Logs del frontend:"
            docker-compose logs --tail=50 frontend
            ;;
        6)
            echo "👋 Saliendo..."
            exit 0
            ;;
        *)
            echo "❌ Opción inválida"
            exit 1
            ;;
    esac
    
    echo ""
    echo "🌐 URLs de acceso:"
    echo "   Frontend: http://localhost:3001"
    echo "   API Gateway: http://localhost"
    echo ""
    echo "💡 Si el problema persiste, revisa los logs con:"
    echo "   docker-compose logs -f frontend"
}

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: No se encontró docker-compose.yml"
    echo "💡 Asegúrate de ejecutar este script desde el directorio raíz del proyecto"
    exit 1
fi

# Ejecutar función principal
main 