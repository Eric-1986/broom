# test tidy, augment, glance methods from nlme-tidiers.R

if (suppressPackageStartupMessages(require(nlme, quietly = TRUE))) {
    context("nlme models")
    
    d <- as.data.frame(ChickWeight)
    colnames(d) <- c("y", "x", "subj", "tx")
    fit <- lme(y ~ tx * x, random = ~x | subj, data = d)
    
    test_that("tidy works on nlme/lme fits", {
        td <- tidy(fit)
        check_tidy(td, exp.col = 4)
    })
    
    test_that("augment works on lme4 fits with or without data", {
        au <- augment(fit)
        aud <- augment(fit, d)
        expect_equal(dim(au), dim(aud))
    })
    dNAs <- d
    dNAs$y[c(1, 3, 5)] <- NA
    
    test_that("augment works on lme fits with NAs and na.omit", {
        fitNAs <- lme(y ~ tx*x, random = ~x | subj, data = dNAs, 
                      na.action = "na.omit")
        au <- augment(fitNAs)
        expect_equal(nrow(au), sum(complete.cases(dNAs)))
    })
    
    
    test_that("augment works on lme fits with na.omit", {
        fitNAs <- lme(y ~ tx*x, random = ~x | subj, data = dNAs, 
                      na.action = "na.exclude")
        
        au <- augment(fitNAs, dNAs)
        
        # with na.exclude, should have NAs in the output where there were NAs in input
        expect_equal(nrow(au), nrow(dNAs))
        expect_equal(complete.cases(au), complete.cases(dNAs))
    })
    
    test_that("glance works on nlme fits", {
        g <- suppressWarnings(glance(fit))
        check_tidy(g, exp.col = 5)
    })
    
    
    testFit <- function(fit, data = NULL) {
        test_that("Pinheiro/Bates fit works", {
            tidy(fit, "fixed")
            tidy(fit)
            g <- suppressWarnings(glance(fit))
            check_tidy(g, exp.col = 5)
            if (is.null(data)) {
                au <- augment(fit)
                check_tidiness(au)
            } else {
                au <- augment(fit, data)
                check_tidiness(au)
            }
        })
    }
    
    testFit(lme(score ~ Machine, data = Machines, random = ~1 | Worker))
    testFit(lme(score ~ Machine, data = Machines, random = ~1 | Worker))
    testFit(lme(score ~ Machine, data = Machines, random = ~1 | Worker / Machine))
    testFit(lme(pixel ~ day + day ^ 2, data = Pixel, random = list(Dog = ~day, Side = ~1)))
    testFit(lme(pixel ~ day + day ^ 2 + Side, data = Pixel, 
                random = list(Dog = ~day, Side = ~1)))
    
    testFit(lme(yield ~ ordered(nitro)*Variety, data = Oats, 
                random = ~1/Block/Variety))
    # There are cases where no data set is returned in the result 
    # We can do nothing about this inconsitency but give a useful error message in augment
    fit  = nlme(conc ~ SSfol(Dose, Time, lKe, lKa, lCl), data = Theoph,
                random = pdDiag(lKe + lKa + lCl ~ 1))
    # Fit without data in returned structure works when data are given
    testFit(fit, Theoph)
     
    # When no data are passed, a meaningful message is issued
    expect_error(augment(fit), "explicit")
}
