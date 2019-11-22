FROM liambindle/penelope:0.1.0-centos7
LABEL maintainer="Liam Bindle <liam.bindle@dal.ca>"

COPY intel/rpm /intel/rpm
RUN  rpm -i /intel/rpm/*.rpm && rm -rf /intel

RUN mkdir /modulefiles/intel \
&&  /usr/share/Modules/bin/createmodule.sh $(find /opt/intel/ -name compilervars.sh) intel64 > /modulefiles/intel/2019.05

COPY *.lic /opt/intel/licenses
RUN . /spack/share/spack/setup-env.sh \
&&  module load intel/2019.05 \
&&  spack compiler find \
&&  spack install netcdf-fortran % intel ^ netcdf % intel -mpi ^ hdf5 % intel +hl

ENV PATH=$PATH:/opt/cmake/bin

RUN . /spack/share/spack/setup-env.sh \
&&  module load intel/2019.05 \
&&  spack install nco ^ netcdf -mpi

RUN . /spack/share/spack/setup-env.sh \
&&  module load intel/2019.05 \
&&  spack install cdo -fftw3 grib2=none -libxml2  ^ netcdf -mpi

RUN rm -rf /opt/intel/licenses

RUN yum groupinstall -y 'Development Tools'

RUN yum install -y zsh \
&&  export ZSH=/usr/share/oh-my-zsh \
&&  wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh

RUN echo "module load intel/2019.05" >> /init.rc \
&&  echo "spack load netcdf%intel" >> /init.rc \
&&  echo "spack load netcdf-fortran%intel" >> /init.rc \
&&  echo "spack load nco" >> /init.rc \
&&  echo "spack load cdo" >> /init.rc


RUN echo "#!/usr/bin/env bash" > /usr/bin/start-container.sh \
&&  echo ". /init.rc" >> /usr/bin/start-container.sh \
&&  echo 'if [ $# -gt 0 ]; then exec "$@"; else zsh ; fi' >> /usr/bin/start-container.sh \
&&  chmod +x /usr/bin/start-container.sh
ENTRYPOINT ["start-container.sh"]
