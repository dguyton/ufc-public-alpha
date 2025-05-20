Database of Intel motherboard characteristics. This information is limited to server-class motherboards with a BMC chip.

## Intel Boards by Server Line and Generation
High-level overview of each series.

| Model Series | Socket | CPU Type | Max # CPUs | Release Year |
| ------------ | ------ | -------- |:----------:|:------------:|
| S5500HV | LGA 1366 | Intel Xeon 5500/5600 Series | 2 | 2009 |
| M20NTP | LGA 4189 | Intel Xeon Scalable Gen 3 | 2 | 2022 |

## Intel Server Motherboards
| Model | Manual Fan<br>Control? | BMC | # Fan<br>Zones | # Fan<br>Headers | Zone 0<br>Fans | Zone 1<br>Fans |
| ----- |:---------------:| --- |:-----------:|:-------------:|:------:|:------:|
| S5500HV | ? | ASPEED AST2050 |
| [M20NTP](https://www.intel.com/content/www/us/en/content-details/840808/intel-server-system-m20ntp1ur-technical-product-specification.html) | Yes | ASPEED AST2500 | 1 | 6 |
| S5000 | ? |
| S7000 | ? |
| S3420 | ? |
| S1200BT | ? |
| E5-4600 | ? |
| E5-2600 | ? |
| E5-2400 | ? |
| E5-1600 | ? |
| X38MI | ? <sup>1</sup> |
| S3200 | ? <sup>1</sup> |
| S5500 | No <sup>2</sup> |
| S5500BC | No <sup>3, 4</sup> | ServerEngines Pilot II | 2 | 5 | 2 | 3 |
| S2600STBR | No <sup>4</sup> |
| S1200V3  No <sup>4</sup> | Emulex Pilot-III |
| S2600CP | No <sup>4</sup> |

<sup>1</sup> Most likely manual fan control is not possible.<br>
<sup>2</sup> First gen to add embedded web server for BMC control.<br>
<sup>3</sup> BMC automatic fan control only (thermal curves).<br>
<sup>4</sup> User can select one of four speed curve ramps, which are: Slow, Medium, Fast, Full Speed<br>
