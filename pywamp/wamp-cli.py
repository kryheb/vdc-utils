from autobahn.asyncio.component import Component, run
from asyncio import sleep
from autobahn.wamp.types import RegisterOptions
import argparse

'''
static void usage(std::string name) {
  std::cerr << "Usage: " << name << '\n'
            << "Options:\n"
            << "\t--help\t\tShow this help message\n"
            << "\t--uri\t\te.g. esmart.vdc1.light0.bulb.rpc\n"
            << "\t--method\tget, post, patch, delete\n"
            << "\t--body\t\tjson string to post e.g.'{\"value\":true}'\n"
            << "\t--subrcribe\tsubscribe uri\n"
            << "\t--publish\tpublish to topic passed as uri with data\n"
            << "\t--address\twamp router address, default localhost\n"
            << std::endl;
}
'''
parser = argparse.ArgumentParser(description='wamp-cli')
parser.add_argument('--uri', type=str, help='e.g. esmart.devices.device1')
parser.add_argument('--method', type=str, help='get, post, patch, delete')
parser.add_argument('--body', type=str, help="json string to post e.g.'{\"value\":true}'")
parser.add_argument('--subscribe', action="store_true", help="subscribe uri (pass uri with underscore \{uri\}._)")
parser.add_argument('--publish', action="store_true", help="publish to topic passed as uri with data")
parser.add_argument('--address', type=str, help="wamp router address, default localhost")

args = parser.parse_args()
address = args.address if args.address else "localhost"
print(address)

component = Component(
    transports=[
        {
            "type": "websocket",
            "url": f"ws://{address}:9002/",
            "endpoint": {
                "type": "tcp",
                "host": f"{address}",
                "port": 9002,
            },
            "options": {
                "open_handshake_timeout": 100,
            }
        },
    ],
    realm="apartment",
)



@component.on_join
async def join(session, details):

    def event_handler(event):
        print(f"Got event {event}")

    print("joined {}: {}".format(session, details))
    await sleep(1)
    if (args.method and args.uri) :
      res = await session.call(f"{args.uri}", f'{{"method": "{args.method}", "content": {args.body if args.body else "{}"}}}')
      print("Result: {}".format(res))
      await session.leave()
    elif (args.subscribe and args.uri):
      try:
        await session.subscribe(event_handler, args.uri)
        print("subscribed to topic")
      except Exception as e:
          print("could not subscribe to topic: {0}".format(e))
    elif (args.publish and args.body):
        session.publish(args.uri, f'{{"content": {args.body if args.body else "{{}}"}}}')
        await session.leave()
    else:
      await session.leave()

if __name__ == "__main__":
    run([component])
