import sysv_ipc
import json
from signal import SIGUSR1
from sys import argv
import os



if __name__ == '__main__':
    try:
        config_path = argv[1]


        if not os.path.exists(config_path):
            os.mkfifo(config_path)
            print('fifo created')
        else:
            print('fifo found')

        with open(config_path, 'r') as pipe:
            resource = json.loads(pipe.readline())
            print('resource received')
            shm = sysv_ipc.attach(id=resource['id'], address=resource['address'], flags=0)
            print('shm attached')

        

        while True:
            buf = input('message: ').encode()
            shm.write(shm.read().strip() + buf)

            os.kill(resource['pid_rx'], SIGUSR1)
    


    finally:
        shm.detach()
        shm.remove()