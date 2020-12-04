function getRandomData(ordinal = false) {

    const NGROUPS = 4,
        MAXLINES = 15,
        MAXSEGMENTS = 20,
        MAXCATEGORIES = 6,
        MINTIME = new Date(1900,01,01);
        
    

    const nCategories = Math.ceil(Math.random()*MAXCATEGORIES),
        categoryLabels = ['Finnegans Wake','Ulysses','A Portrait Of the Artis','Dubliners','Giacomo Joyce','Steven Hero','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'],
        groupLabels = ['Library','Drafts','Editions','Letters'];

    return [...Array(NGROUPS).keys()].map(i => ({
        group: groupLabels[i],
        data: getGroupData()
    }));

    //

    function getGroupData() {

        return [...Array(Math.ceil(Math.random()*MAXLINES)).keys()].map(i => ({
            label: 'label' + (i+1),
            data: getSegmentsData()
        }));

        //

        function getSegmentsData() {
            const nSegments = Math.ceil(Math.random()*MAXSEGMENTS),
                segMaxLength = Math.round(((new Date())-MINTIME)/nSegments);
            let runLength = MINTIME;

            return [...Array(nSegments).keys()].map(i => {
                const tDivide = [Math.random(), Math.random()].sort(),
                    start = new Date(runLength.getTime() + tDivide[0]*segMaxLength),
                    end = new Date(runLength.getTime() + tDivide[1]*segMaxLength);

                runLength = new Date(runLength.getTime() + segMaxLength);

                return {
                    timeRange: [start, end],
                    val: ordinal ? categoryLabels[Math.ceil(Math.random()*nCategories)] : Math.random(),
                    labelVal: toString(Math.random())
                };
            });

        }
    }
}