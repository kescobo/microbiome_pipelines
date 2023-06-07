cd bzip2
sudo docker build --no-cache bzip2:mamba-v1.0.8 .
cd ../kneaddata
sudo docker build --no-cache kneaddata-nodb:mamba-v0.12 .
cd ../metaphlan
sudo docker build --no-cache metaphlan-nodb:mamba-v3.1 .
cd ../humann
sudo docker build --no-cache humann-nodb:mamba-v3.7 .

docker tag bzip2:mamba-v1.0.8 public.ecr.aws/j5i5h1i5/bzip2:mamba-v1.0.8
docker tag kneaddata-nodb:mamba-v0.12 public.ecr.aws/j5i5h1i5/kneaddata-nodb:mamba-v0.12
docker tag metaphlan-nodb:mamba-v3.1 public.ecr.aws/j5i5h1i5/metaphlan-nodb:mamba-v3.1
docker tag humann-nodb:mamba-v3.7 public.ecr.aws/j5i5h1i5/humann-nodb:mamba-v3.7

docker push bzip2:mamba-v1.0.8
docker push kneaddata-nodb:mamba-v0.12
docker push metaphlan-nodb:mamba-v3.1
docker push humann-nodb:mamba-v3.7