package utils

import (
	"crypto/rand"
	"encoding/json"
	"fmt"
	"math/big"
	"net/http"
	"time"
)

// WriteJSON escribe una respuesta JSON en el escritor de respuestas HTTP
func WriteJSON(w http.ResponseWriter, status int, data interface{}) error {
	// Establecer el tipo de contenido
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	// Marshal and write JSON response
	return json.NewEncoder(w).Encode(data)
}

// DecodeJSON decodifica el cuerpo de la solicitud JSON en la estructura proporcionada
func DecodeJSON(r *http.Request, v interface{}) error {
	// Decodificar JSON del cuerpo de la solicitud
	if err := json.NewDecoder(r.Body).Decode(v); err != nil {
		return err
	}
	defer r.Body.Close()

	return nil
}

// GenerateTimestamp genera un identificador de tiempo único
func GenerateTimestamp() string {
	return fmt.Sprintf("%d", time.Now().UnixNano())
}

// GenerateTicketID genera un nuevo ID de ticket en el formato TICKET-YYYYMMDD-HHMMSS
func GenerateTicketID() string {
	return fmt.Sprintf("TICKET-%s", time.Now().Format("20060102-150405"))
}

// GenerateMessageID genera un nuevo ID de mensaje en el formato MSG-TIMESTAMP
func GenerateMessageID() string {
	return fmt.Sprintf("MSG-%d", time.Now().UnixNano())
}

// SetCORS establece los encabezados CORS en la respuesta
func SetCORS(w http.ResponseWriter) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With, X-Widget-ID, X-Widget-Token")
	w.Header().Set("Access-Control-Allow-Credentials", "true")
}

// HandleCORS maneja las solicitudes de preflight CORS
func HandleCORS(w http.ResponseWriter, r *http.Request) bool {
	// Establecer encabezados CORS
	SetCORS(w)

	// Manejar la solicitud de preflight OPTIONS
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusNoContent)
		return true
	}

	return false
}

// GetStringFromMap extrae un valor string de un mapa, con manejo seguro
// Si la clave no existe o el valor no es string, devuelve una cadena vacía
func GetStringFromMap(data map[string]interface{}, key string) string {
	if data == nil {
		return ""
	}

	if val, exists := data[key]; exists {
		if strVal, ok := val.(string); ok {
			return strVal
		}
	}

	return ""
}

// GenerateRandomPassword genera una contraseña aleatoria de la longitud especificada
func GenerateRandomPassword(length int) string {
	if length <= 0 {
		length = 12 // longitud mínima por defecto
	}

	// Caracteres que pueden aparecer en la contraseña
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}|;:,.<>?"
	charsetLength := big.NewInt(int64(len(charset)))

	// Construir la contraseña
	password := make([]byte, length)
	for i := 0; i < length; i++ {
		// Generar un índice aleatorio seguro
		randomIndex, err := rand.Int(rand.Reader, charsetLength)
		if err != nil {
			// En caso de error, usar un valor pseudo-aleatorio basado en la hora
			randomIndex = big.NewInt(int64(time.Now().Nanosecond() % len(charset)))
		}
		// Asignar el carácter aleatorio
		password[i] = charset[randomIndex.Int64()]
	}

	return string(password)
}
