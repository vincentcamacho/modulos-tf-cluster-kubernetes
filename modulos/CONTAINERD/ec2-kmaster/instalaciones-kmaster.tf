variable "INSTALA_DOCKER" {
  type = list(any)
  default = [
    "sudo apt remove docker docker-engine docker.io containerd runc",
    "sudo apt update",
    "sudo apt install -y ca-certificates curl gnupg lsb-release",
    "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
    "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
    "sudo apt update -y",
    "sudo apt install -y docker-ce docker-ce-cli containerd.io",
    "sudo usermod -aG docker ansible",
    "sudo systemctl start docker",
    "sudo systemctl enable docker",
  ]
}

variable "INSTALA_CONTAINERD" {
  type = list(any)
  default = [
    "echo \"[PASO 1] Apagar y deshabilitar la SWAP (memoria en disco)\"",
    "swapoff -a",
    "sudo sed -i '/swap/d' /etc/fstab",

    "echo \"[PASO 2] Agregar configuraciones para KUBERNETES necesarias en el Kernel \"",
    "sudo cp /tmp/k8s.conf /etc/sysctl.d/k8s.conf",
    "sudo sysctl --system >/dev/null 2>&1",

    "echo \"[PASO 3] Habilitar y cargar modulos necesarios para CONTAINERD en el Kernel \"",
    "sudo cp /tmp/containerd.conf /etc/modules-load.d/containerd.conf",
    "sudo modprobe overlay",
    "sudo modprobe br_netfilter",

    "echo \"[PASO 4] Instalar CONTAINERD \"",
    "sudo apt update -qq >/dev/null 2>&1",
    "sudo apt install -qq -y containerd apt-transport-https >/dev/null 2>&1",
    "sudo mkdir -p /etc/containerd",
    "containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1",
    "sudo sed -i 's|SystemdCgroup = false|SystemdCgroup = true|g' /etc/containerd/config.toml",
    
    "echo \"[PASO 5] Reiniciar y habilitar servicio CONTAINERD \"",
    "sudo systemctl restart containerd",
    "sudo systemctl enable containerd >/dev/null 2>&1",

    "echo \"[PASO 6] Configurar ALIAS linux, la MERMA de la MERMELADA\"",
    "git clone https://github.com/jvinc86/alias-ubuntu.git >/dev/null 2>&1",
    "cd alias-ubuntu",
    "sed -i 's/mi_shell=zshrc/mi_shell=bashrc/g' alias.sh",
    "bash alias.sh >/dev/null 2>&1",
    "cd .. && rm -rf alias-ubuntu/",
  ]
}

variable "INSTALA_KUBE_COMPONENTES" {
  type = list(any)
  default = [
    "echo \"[PASO 1] Actualizar APT repositorio\"",
    "sudo apt update -qq >/dev/null 2>&1",

    "echo \"[PASO 2] Agregar repositorio APT para KUBERNETES\"",
    "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - > /dev/null 2>&1",
    "sudo apt-add-repository -y -s \"deb http://apt.kubernetes.io/ kubernetes-xenial main\" > /dev/null 2>&1",

    "echo \"[PASO 3] Instalar KUBERNETES Componentes\"",
    "echo \"   [3.1] Instala kubeadm (Herramienta permite crear CLUSTER KUBERNETES. Comandos: kubeadm init, kubeadm join)\"",
    "echo \"   [3.2] Instala kubelet (Agente que se asegura de que los contenedores estén corriendo)\"",
    "echo \"   [3.3] Instala kubectl (CLI - Command-line interface)\"",
    "sudo apt install -y kubeadm=1.24.0-00 kubelet=1.24.0-00 kubectl=1.24.0-00 >/dev/null 2>&1",

    "echo \"[PASO 4] Prevenir que componentes kubernetes se actualizen o remuevan (apt-mark hold)\"",
    "sudo apt-mark hold kubelet kubeadm kubectl >/dev/null 2>&1",
  ]
}

variable "INICIA_MASTER_K8S" {
  type = list(any)
  default = [
    "echo \"[PASO 1] Descargar IMAGENES para Cluster KUBERNETES (api, scheduler, etcd, etc.)\"",
    "sudo kubeadm config images pull >/dev/null 2>&1",

    "echo \"[PASO 2] Inicializar MASTER K8s (CONTROL PLANE) con la herramienta kubeadm\"",
    "sudo kubeadm init --apiserver-advertise-address=10.0.150.90 --pod-network-cidr=192.168.0.0/16 | tee ~/01-Logs-inicializacion-master.log >/dev/null 2>&1",

    "echo \"[PASO 3] TRUCAZO: Guarda en archivo el comando JOIN que usaran los WORKER NODES\"",
    "sudo kubeadm token create --print-join-command >> ~/comando_JOIN_para_workers.sh",

    "echo \"[PASO 4] Instalar Red CALICO (contenedores que gestionan las redes)\"",
    "sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml | tee ~/02-Logs-deploy-red-calisto.log >/dev/null 2>&1",

    "echo \"[PASO 5] Para mi usuario, copiar /etc/kubernetes/admin.conf en mi HOME\"",
    "mkdir -p ~/.kube",
    "sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config",
    "sudo chown $(id -u):$(id -g) ~/.kube/config",

    "echo \"[PASO 6] Para usuario root, configurar variable de ambiente KUBECONFIG para root\"",
    "echo \"export KUBECONFIG=/etc/kubernetes/admin.conf\" | sudo tee -a /root/.bashrc >/dev/null 2>&1",
  ]
}