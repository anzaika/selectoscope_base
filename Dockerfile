FROM anzaika/ruby

ENV TIMESTAMP 22-07-2016

# Additional packages
RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list &&\
    gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 &&\
    gpg -a --export E084DAB9 | sudo apt-key add - &&\
    apt-get update -qq &&\
    apt-get install -y --no-install-recommends r-base bioperl bioperl-run libexpat-dev gengetopt

RUN curl --silent --location https://deb.nodesource.com/setup_4.x | sudo bash - &&\
    apt-get install -y nodejs &&\
    npm install webpack webpack-dev-server -g

# Installing BioPerl this way is very slow and I even don't know if it's the right way
# #####################
# #      BioPerl      #
# #####################
#
# RUN apt-get install -y --no-install-recommends libexpat-dev libcgi-session-perl libclass-base-perl libgd-gd2-perl \
#   && PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install Bundle::CPAN;quit' \
#   && PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install Text::Shellwords' \
#   && PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install Bundle::LWP' \
#   && PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install Bio::SeqIO'

#####################
#   Bioconductor    #
#####################

RUN R -e "source('https://bioconductor.org/biocLite.R');biocLite('qvalue')"

#####################
#       PAML        #
#####################

RUN mkdir -p /usr/src/paml \
  && curl -SL "http://abacus.gene.ucl.ac.uk/software/paml4.9a.tgz" \
  | tar zxC /usr/src/paml \
  && cd /usr/src/paml/paml4.9a/src \
  && make -j"$(nproc)" \
  && mv codeml /usr/bin/ \
  && mv baseml /usr/bin/ \
  && mv basemlg /usr/bin/ \
  && mv chi2 /usr/bin/ \
  && mv evolver /usr/bin/ \
  && mv infinitesites /usr/bin/ \
  && mv mcmctree /usr/bin/ \
  && mv pamp /usr/bin/ \
  && mv yn00 /usr/bin/ \
  && rm -rf /usr/src

# ####################
# #    Muscle        #
# ####################
# RUN mkdir -p /usr/src/muscle \
#   && curl -SL "http://www.drive5.com/muscle/downloads3.8.31/muscle3.8.31_i86linux64.tar.gz" \
#   | tar xvzC /usr/src/muscle \
#   && cd /usr/src/muscle \
#   && mv muscle3.8.31_i86linux64 /usr/local/bin/muscle \
#   && rm -rf /usr/src/muscle

#####################
#      Guidance     #
#####################
RUN mkdir -p /usr/src/guidance \
  && curl -SL "http://guidance.tau.ac.il/ver2/guidance.v2.01.tar.gz" \
  | tar xvzC /usr/src/guidance/ \
  && cd /usr/src/guidance/guidance.v2.01 \
  && sed -i 's/time\ -p//g' /usr/src/guidance/guidance.v2.01/www/Guidance/exec/HoT_COS_GUIDANCE2.pl \
  && sed -i 's/time\ -p//g' /usr/src/guidance/guidance.v2.01/www/Guidance/exec/HoT/COS.pl \
  && make -j"$(nproc)"

##########################
#       DNDSTolls        #
##########################
RUN mkdir -p /usr/src/dndstools \
  && git clone https://anzaika@bitbucket.org/Davydov/dndstools.git /usr/src/dndstools/ \
  && cd /usr/src/dndstools \
  && chmod +x cdmw.py \
  && mv cdmw.py /usr/local/bin/ \
  && chmod +x mlc2csv.py \
  && mv mlc2csv.py /usr/local/bin/ \
  && rm -rf /usr/src

#####################
#      PhyML        #
#####################

RUN mkdir -p /usr/src/beagle &&\
    cd /usr/src &&\
    git clone --depth=1 https://github.com/beagle-dev/beagle-lib.git beagle &&\
    cd beagle &&\
    ./autogen.sh &&\
    ./configure --prefix=$HOME &&\
    make install &&\
    rm -rf /usr/src/beagle

RUN mkdir -p /usr/src/phyml \
  && cd /usr/src \
  && git clone https://github.com/stephaneguindon/phyml.git\
  && cd phyml \
  && sh ./autogen.sh \
  && ./configure \
  && make -j"$(nproc)" \
  && mv src/phyml /usr/local/bin \
  && rm -rf /usr/src

#####################
#       mafft       #
#####################

ENV MAFFT_VERSION 7.273

RUN mkdir -p /usr/src/mafft \
  && curl -SL "http://mafft.cbrc.jp/alignment/software/mafft-$MAFFT_VERSION-with-extensions-src.tgz" \
  | tar xvzC /usr/src/mafft \
  && cd /usr/src/mafft/mafft-$MAFFT_VERSION-with-extensions/core \
  && make -j"$(nproc)" \
  && make install \
  && rm -rf /usr/src

#####################
#      Gblocks      #
#####################

RUN mkdir -p /usr/src/gblocks \
  && curl -SL "http://molevol.cmima.csic.es/castresana/Gblocks/Gblocks_Linux64_0.91b.tar.Z" \
  | tar xvzC /usr/src/gblocks \
  && cd /usr/src/gblocks/Gblocks_0.91b \
  && cp Gblocks /usr/local/bin \
  && rm -rf /usr/src

#####################
# fastcodeml-source #
#####################

ENV MATH_LIB_NAMES openblas;lapack
COPY fast_build_config.txt /usr/src/CMakeLists.txt
RUN apt-get install -y --no-install-recommends \
    gfortran cmake-curses-gui libopenblas-dev \
    libopenblas-base liblapack-dev libnlopt-dev libboost-all-dev \
    && mkdir -p /usr/src \
    && cd /usr/src \
    && git clone https://gitlab.isb-sib.ch/phylo/fastcodeml.git \
    && cd fastcodeml \
    && git reset --hard f00fdf2 \
    && cp ../CMakeLists.txt . \
    && cmake . \
    && make -j"$(nproc)" \
    && mv fast /usr/bin/ \
    && rm -rf /usr/src
#####################

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
