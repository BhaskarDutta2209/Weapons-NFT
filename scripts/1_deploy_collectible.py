from brownie import WeaponsCollectible, accounts, network, config
from scripts.helpful_scripts import fund_advanced_collectible

def main():
    dev = accounts.add(config['wallets']['from_key'])
    print(network.show_active())
    publish_source = True
    advancedCollectible = WeaponsCollectible.deploy(
        config['networks'][network.show_active()]['vrf_coordinator'],
        config['networks'][network.show_active()]['link_token'],
        config['networks'][network.show_active()]['keyhash'],
        "https://gateway.pinata.cloud/ipfs/QmeNG2nCmRBLN6MJnLu3GyaUnHVc2n3teKWePHPVHtiVsx",
        "https://gateway.pinata.cloud/ipfs/QmZ2d37ZQDiTQWWf8mwLPKTZLdzbQU5gQboYJLxG99f3Gh",
        {"from": dev},
        publish_source = publish_source
    )

    fund_advanced_collectible(advancedCollectible)

    return advancedCollectible
