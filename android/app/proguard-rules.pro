# geolocator_android referencia clases de Google Play Services en su código,
# pero esta app usa el LocationManager nativo y excluye GMS del build.
# Estas clases nunca se ejecutan, así que solo silenciamos los avisos de R8.
-dontwarn com.google.android.gms.**
