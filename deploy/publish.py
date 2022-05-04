import argparse
import subprocess
import time
import os



class MobNativeSdkFlutterPublish:
    def __init__(self, args):
        print('initializing publish command')
        # subprocess.Popen("mkdir ./.pub-cache", shell=True, stderr=subprocess.PIPE,
        #                  stdout=subprocess.PIPE)
        os.mkdir("./.pub-cache")
        os.environ["PUB_CACHE"] = "/publishers-mobile-native-sdk-flutter/.pub-cache"
        credentials_file = open("./.pub-cache/credentials.json", "w")
        credentials_file.write("{")
        credentials_file.write("\n")
        credentials_file.write(f'     \"accessToken\": \"{args.access_token}\",')
        credentials_file.write("\n")
        credentials_file.write(f'     \"refreshToken\": \"{args.refresh_token}\",')
        credentials_file.write("\n")
        credentials_file.write(f'     \"idToken\": \"{args.id_token}\",')
        credentials_file.write("\n")
        credentials_file.write(f'     \"tokenEndpoint\": \"{args.token_endpoint}\",')
        credentials_file.write("\n")
        credentials_file.write(f'     \"scopes\": [\"openid\", \"https://www.googleapis.com/auth/userinfo.email\"],')
        credentials_file.write("\n")
        credentials_file.write(f'     \"expiration\": {args.expiration}')
        credentials_file.write("\n")
        credentials_file.write("}")
        credentials_file.write("\n")
        credentials_file.close
        # subprocess.Popen("mkdir /root/.pub-cache/", shell=True, stderr=subprocess.PIPE,
        #                  stdout=subprocess.PIPE)
        # # subprocess.Popen("mv credentials.json /root/.pub-cache/", shell=True, stderr=subprocess.PIPE,
        # #                  stdout=subprocess.PIPE)
        # shutil.move("./credentials.json", "/root/.pub-cache/credentials.json")

        if args.dry_run == 'Y' or args.dry_run == 'y':
            self.command = "export PUB_DEV_PUBLISH_ACCESS_TOKEN={access_token};" \
                           "export PUB_DEV_PUBLISH_REFRESH_TOKEN={refresh_token};" \
                           "export PUB_DEV_PUBLISH_TOKEN_ENDPOINT={token_endpoint};" \
                           "export PUB_DEV_PUBLISH_ID_TOKEN={id_token};" \
                           "export PUB_DEV_PUBLISH_EXPIRATION={expiration};" \
                           "dart pub publish --dry-run".format(
                access_token=args.access_token,
                refresh_token=args.refresh_token,
                token_endpoint=args.token_endpoint,
                id_token=args.id_token,
                expiration=args.expiration)
        else:
            # self.command = "export PUB_DEV_PUBLISH_ACCESS_TOKEN={access_token};" \
            #                "export PUB_DEV_PUBLISH_REFRESH_TOKEN={refresh_token};" \
            #                "export PUB_DEV_PUBLISH_TOKEN_ENDPOINT={token_endpoint};" \
            #                "export PUB_DEV_PUBLISH_ID_TOKEN={id_token};" \
            #                "export PUB_DEV_PUBLISH_EXPIRATION={expiration};" \
            #                "dart pub publish ".format(
            #     access_token=args.access_token,
            #     refresh_token=args.refresh_token,
            #     token_endpoint=args.token_endpoint,
            #     id_token=args.id_token,
            #     expiration=args.expiration)
            self.command = "dart pub publish --force"

        print(f'command= {self.command}')

    def publish(self):
        print("Pub Dev Publish Start")
        p = subprocess.Popen(self.command, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
        time.sleep(30)
        (output, err) = p.communicate()
        print(output.decode('utf-8'))
        print(err.decode('utf-8'))
        print("Pub Dev Publish Start")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-a", "--access_token", help="accessToken")
    parser.add_argument("-r", "--refresh_token", help="refreshToken")
    parser.add_argument("-t", "--token_endpoint", help="tokenEndpoint")
    parser.add_argument("-i", "--id_token", help="idToken")
    parser.add_argument("-e", "--expiration", help="expiration")
    parser.add_argument("-d", "--dry_run", help="dryRun")
    args = parser.parse_args()
    publish = MobNativeSdkFlutterPublish(args)
    publish.publish()
