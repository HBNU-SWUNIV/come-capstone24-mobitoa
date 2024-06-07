## 1. Import modules
from requests import Session
import json
from typing import Iterable, Optional







## 2. Class(es)
class LuCIRPC:
    def __init__(
            self, 
            hostname: str='192.168.1.1', 
            username: str='root', 
            password: str='', 
            timeout: int=30, 
    ):
        self.session = Session()
        self.username = username
        self.password = password
        self.url = f'http://{hostname}/cgi-bin/luci/rpc/'
        self.token_query = ''
        self.timeout = timeout

        self.__refresh_token()



    def __refresh_token(self):
        response = self.session.post(
            url=self.url + 'auth', 
            data=json.dumps({'method': 'login', 'params': [self.username, self.password]}), 
            timeout=self.timeout, 
        )

        assert response.status_code == 200, 'Failed to authenticate'
        self.token_query = f'?auth={response.json()["result"]}'



    def call(
            self, 
            library: str,
            method: str, 
            params: Optional[Iterable]=None, 
    ):
        response = self.session.post(
            url=self.url + library + self.token_query, 
            data=json.dumps({'method': method, 'params': params} if params else {'method': method}), 
            timeout=self.timeout, 
        )

        if response.status_code in (401, 403):
            self.__refresh_token()
            return self.rpc_call(library, method, params)
        elif response.status_code == 404:
            raise Exception('404 Not found. check installation of package "luci-mod-rpc"')
        elif response.status_code == 200:
            if (err := response.json()['error']):
                raise Exception(f'method: {method}, error: {err}')
            else:
                return response.json()
    


    def get_ipv4_hints(self):
        return self.call('sys', 'net.ipv4_hints')['result']
    
    def get_ipv6_hints(self):
        return self.call('sys', 'net.ipv6_hints')['result']
    
    def get_mac_hints(self):
        return self.call('sys', 'net.mac_hints')['result']







## 3. Main (Testcode)
if __name__ == '__main__':
    for _ in range(10):
        print(*LuCIRPC().get_ipv4_hints())
        print(*LuCIRPC().get_ipv6_hints())
        print(*LuCIRPC().get_mac_hints())