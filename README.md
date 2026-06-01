# Weather CLI

```
weather --city "Dallas,TX"
```
Outputs

```
75°F
```

```
weather --lon [LONGITUDE] --lat [LATITUDE]
```

For celsius temp:

```
weather --type=C --city "Orlando,FL"
```
Calls nominatim for city coords if not provided. Calls weather.gov for weather data

# Installation

```
sh binary_creator.sh
cp weather_linux_x86_64 /usr/local/bin
```
