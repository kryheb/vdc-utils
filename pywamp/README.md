examples:
```
python wamp-cli.py --uri sonos.players.RINCON_7828CAB43CC801400:3695806301._ --address localhost --publish --body '{"event":"data"}'
python wamp-cli.py --uri sonos.players.RINCON_7828CAB43CC801400:3695806301._ --address localhost --subscribe
python wamp-cli.py --uri sonos.players.RINCON_7828CAB43CC801400:3695806301 --address localhost --method patch --body '{"playback": {"play":{}}}'
python wamp-cli.py --uri sonos.players.RINCON_7828CAB43CC801400:3695806301 --method get

```

environment
```
git clone https://github.com/kryheb/vdc-utils.git
cd vdc-utils/pywamp

virtualenv -p python3 venv
source venv/bin/activate
pip install autobahn[asyncio,encryption,serialization,xbr]
pip install argparse

```
