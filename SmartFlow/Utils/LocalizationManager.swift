import Foundation
import SwiftUI

/// Centralized localization manager for SmartFlow.
/// Reads the user's chosen language from @AppStorage("appLanguage") and provides translations.
class LocalizationManager {
    static let shared = LocalizationManager()
    
    var language: String {
        UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
    }
    
    private let strings: [String: [String: String]] = [
        // ── General ──
        "Cancel":           ["es": "Cancelar"],
        "Continue":         ["es": "Continuar"],
        "Done":             ["es": "Listo"],
        "OK":               ["es": "Aceptar"],
        "Reset":            ["es": "Restablecer"],
        "Save":             ["es": "Guardar"],
        "Delete":           ["es": "Eliminar"],
        "Error":            ["es": "Error"],
        "Settings":         ["es": "Ajustes"],
        "Close":            ["es": "Cerrar"],
        "Try Again":        ["es": "Reintentar"],
        "Skip for now":     ["es": "Omitir por ahora"],
        
        // ── Onboarding ──
        "Choose Language":                      ["es": "Elegir Idioma"],
        "Welcome to SmartFlow":                 ["es": "Bienvenido a SmartFlow"],
        "Monitor your water usage in real-time": ["es": "Monitorea tu consumo de agua en tiempo real"],
        "Setup Sensor Now":                     ["es": "Configurar Sensor Ahora"],
        
        // ── Tabs ──
        "Home":         ["es": "Inicio"],
        "Set Limit":    ["es": "Establecer Límite"],
        "History":      ["es": "Historial"],
        "Achievements": ["es": "Logros"],
        
        // ── Home View ──
        "Today's Usage":        ["es": "Uso de Hoy"],
        "Daily Limit":          ["es": "Límite Diario"],
        "No limit set":         ["es": "Sin límite"],
        "Flow Rate":            ["es": "Flujo"],
        "Total Volume":         ["es": "Volumen Total"],
        "Quick Actions":        ["es": "Acciones Rápidas"],
        "Reset Counter":        ["es": "Resetear Contador"],
        "View History":         ["es": "Ver Historial"],
        "Connect Device":       ["es": "Conectar Dispositivo"],
        "Set Usage Limit":      ["es": "Establecer Límite"],
        "Good morning":         ["es": "Buenos días"],
        "Good afternoon":       ["es": "Buenas tardes"],
        "Good evening":         ["es": "Buenas noches"],
        
        // ── Settings View ──
        "Flow Sensor":          ["es": "Sensor de Flujo"],
        "Water Flow Sensor":    ["es": "Sensor de Flujo de Agua"],
        "Connected":            ["es": "Conectado"],
        "Disconnected":         ["es": "Desconectado"],
        "Connecting":           ["es": "Conectando"],
        "Connection Failed":    ["es": "Conexión Fallida"],
        "Connect":              ["es": "Conectar"],
        "Disconnect":           ["es": "Desconectar"],
        "Manual Connection":    ["es": "Conexión Manual"],
        "Enter IP Manually":    ["es": "Ingresar IP Manualmente"],
        "Cancel Manual Setup":  ["es": "Cancelar Configuración Manual"],
        "Setup New Device":     ["es": "Configurar Nuevo Dispositivo"],
        "Device Information":   ["es": "Información del Dispositivo"],
        "IP Address":           ["es": "Dirección IP"],
        "Connection Status":    ["es": "Estado de Conexión"],
        "Calibration Factor":   ["es": "Factor de Calibración"],
        "Notifications":        ["es": "Notificaciones"],
        "Enable Notifications": ["es": "Activar Notificaciones"],
        "Daily Reminder":       ["es": "Recordatorio Diario"],
        "Usage Alerts":         ["es": "Alertas de Uso"],
        "Units & Display":      ["es": "Unidades y Pantalla"],
        "Volume Unit":          ["es": "Unidad de Volumen"],
        "Dark Mode":            ["es": "Modo Oscuro"],
        "Data Management":      ["es": "Gestión de Datos"],
        "Export Data":          ["es": "Exportar Datos"],
        "Reset All Data":       ["es": "Restablecer Todos los Datos"],
        "Apple Watch":          ["es": "Apple Watch"],
        "Sync with Apple Watch": ["es": "Sincronizar con Apple Watch"],
        "Auto-sync enabled":    ["es": "Sincronización automática activada"],
        "Support":              ["es": "Soporte"],
        "FAQ & Help":           ["es": "Preguntas Frecuentes"],
        "About SmartFlow":      ["es": "Acerca de SmartFlow"],
        "Developer Options":    ["es": "Opciones de Desarrollador"],
        "Always Show Onboarding": ["es": "Mostrar Siempre el Tutorial"],
        "Current Limit":        ["es": "Límite Actual"],
        "Change":               ["es": "Cambiar"],
        
        // ── Device Setup View ──
        "Setup Device":             ["es": "Configurar Dispositivo"],
        "Find":                     ["es": "Buscar"],
        "WiFi":                     ["es": "WiFi"],
        "Set Up Your Sensor":       ["es": "Configura Tu Sensor"],
        "Make sure your ESP32 is powered on and the LED is blinking. This means it's ready for setup.":
            ["es": "Asegúrate de que tu ESP32 esté encendido. Esto significa que está listo para configurar."],
        "Power on your ESP32 board": ["es": "Enciende tu placa ESP32"],
        "Wait for the LED to start blinking": ["es": "Espera a que el LED parpadee"],
        "Keep it within Bluetooth range": ["es": "Mantenlo dentro del alcance Bluetooth"],
        "Start Setup":              ["es": "Iniciar Configuración"],
        "Searching for Sensor...":  ["es": "Buscando Sensor..."],
        "Looking for your SmartFlow sensor via Bluetooth. Make sure the LED on your ESP32 is blinking.":
            ["es": "Buscando tu sensor SmartFlow por Bluetooth. Asegúrate de que el LED de tu ESP32 esté parpadeando."],
        "Connecting...":            ["es": "Conectando..."],
        "Found:":                   ["es": "Encontrado:"],
        "Sensor Connected!":        ["es": "¡Sensor Conectado!"],
        "Now enter your WiFi network details so the sensor can connect to your network.":
            ["es": "Ahora ingresa los datos de tu red WiFi para que el sensor se conecte."],
        "WiFi Network Name":        ["es": "Nombre de Red WiFi"],
        "Enter WiFi SSID":          ["es": "Ingresa el SSID"],
        "WiFi Password":            ["es": "Contraseña WiFi"],
        "Enter password":           ["es": "Ingresa la contraseña"],
        "Connect to WiFi":          ["es": "Conectar a WiFi"],
        "Connecting to WiFi...":    ["es": "Conectando a WiFi..."],
        "Please don't close the app.": ["es": "Por favor no cierres la app."],
        "Sensor is joining your network...": ["es": "El sensor se está uniendo a tu red..."],
        "Setup Complete!":          ["es": "¡Configuración Completa!"],
        "Your SmartFlow sensor is connected to WiFi and ready to monitor water usage.":
            ["es": "Tu sensor SmartFlow está conectado al WiFi y listo para monitorear el consumo de agua."],
        "Network":                  ["es": "Red"],
        "Setup Failed":             ["es": "Configuración Fallida"],
        
        // ── History View ──
        "Water Usage History":      ["es": "Historial de Consumo"],
        "Today":                    ["es": "Hoy"],
        "Week":                     ["es": "Semana"],
        "Month":                    ["es": "Mes"],
        "Year":                     ["es": "Año"],
        "Average":                  ["es": "Promedio"],
        "Total":                    ["es": "Total"],
        "No data available":        ["es": "Sin datos disponibles"],
        
        // ── Achievements View ──
        "Level":                    ["es": "Nivel"],
        "XP":                       ["es": "XP"],
        "Shop":                     ["es": "Tienda"],
        "Badges":                   ["es": "Insignias"],
        "Streaks":                  ["es": "Rachas"],
        "Locked":                   ["es": "Bloqueado"],
        "Unlocked":                 ["es": "Desbloqueado"],
        
        // ── Set Limit View ──
        "Set Daily Limit":          ["es": "Establecer Límite Diario"],
        "Common Limits":            ["es": "Límites Comunes"],
        "Custom Amount":            ["es": "Cantidad Personalizada"],
        
        // ── Reset Alert ──
        "This will permanently delete all your water usage history and reset your settings. This action cannot be undone.":
            ["es": "Esto eliminará permanentemente tu historial de consumo y restablecerá tus ajustes. Esta acción no se puede deshacer."],
    ]
    
    func localize(_ key: String) -> String {
        let lang = language.starts(with: "es") ? "es" : "en"
        if lang == "en" { return key }
        return strings[key]?[lang] ?? key
    }
}

/// Shorthand for localization: L("key")
func L(_ key: String) -> String {
    LocalizationManager.shared.localize(key)
}
