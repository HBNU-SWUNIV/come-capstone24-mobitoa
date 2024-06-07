import sysv_ipc
import json
from time import sleep
from signal import signal, SIGUSR1
import os
from sys import argv



if __name__ == '__main__':
    try:
        config_path = argv[1]



        if not os.path.exists(config_path):
            os.mkfifo(config_path)
            print('fifo created')
        else:
            print('fifo found')

        with open(config_path, 'w') as pipe:
            shm = sysv_ipc.SharedMemory(key=None, flags=(sysv_ipc.IPC_CREAT | sysv_ipc.IPC_EXCL), mode=0o0666, size=sysv_ipc.PAGE_SIZE)
            print('shm created')
            json.dump(obj=dict(id=shm.id, address=shm.address, pid_rx=os.getpid()), fp=pipe)
            print('resource transmitted')




        def sigusr1_handler(signum, frame):
            print(f'shm: {shm.read().strip()}')

        signal(SIGUSR1, sigusr1_handler)
        


        while True:
            sleep(10000)
    


    finally:
        shm.detach()
        shm.remove()